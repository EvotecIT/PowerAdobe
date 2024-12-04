function Invoke-AdobeBulk {
    <#
    .SYNOPSIS
    Executes bulk operations on Adobe users.

    .DESCRIPTION
    The Invoke-AdobeBulk cmdlet performs multiple Adobe user operations in a single request. It processes actions defined in a script block and handles errors accordingly.

    .PARAMETER Actions
    A script block containing the bulk actions to execute.

    .PARAMETER Suppress
    Suppresses output of errors.

    .EXAMPLE
    Invoke-AdobeBulk {
        Add-AdobeUser -EmailAddress "john.doe@example.com" -Country "US" -FirstName "John" -LastName "Doe" -Type "createFederatedID" -BulkProcessing
        Set-AdobeUser -EmailAddress "john.doe@example.com" -LastName "Doe-Smith" -BulkProcessing
    }
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [scriptblock] $Actions,
        [switch] $Suppress
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Invoke-AdobeBulk - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    $AllActions = & $Actions
    [Array] $ActionsToExecute = foreach ($Action in $AllActions) {
        $Action
    }

    # Initialize aggregation variables
    $aggregatedResult = [ordered] @{
        completed           = 0
        notCompleted        = 0
        completedInTestMode = 0
        result              = 'success'
        errors              = @()
    }

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess("Updates", 'Do bulk updates')) { $false } else { $true }
    }

    # Process actions in batches of 20
    for ($i = 0; $i -lt $ActionsToExecute.Count; $i += 20) {
        $Batch = $ActionsToExecute[$i..([math]::Min($i + 19, $ActionsToExecute.Count - 1))]

        $Batch | ConvertTo-Json -Depth 5 | Write-Verbose

        $batchOutput = Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Batch -QueryParameter $QueryParameter
        foreach ($ErrorMessage in $batchOutput.Errors) {
            Write-Warning -Message "Invoke-AdobeBulk - Processing error [user: $($ErrorMessage.User), index: $($ErrorMessage.Index)] - $($ErrorMessage.Message)"
        }

        # Aggregate results
        $aggregatedResult.completed += $batchOutput.completed
        $aggregatedResult.notCompleted += $batchOutput.notCompleted
        $aggregatedResult.completedInTestMode += $batchOutput.completedInTestMode
        if ($batchOutput.errors) {
            $aggregatedResult.errors += $batchOutput.errors
            #$aggregatedResult.failed += $batchOutput.errors.Count
        }

        # Update overall result status
        if ($batchOutput.result -eq 'failure') {
            $aggregatedResult.result = 'failure'
        } elseif ($batchOutput.result -ne 'success' -and $aggregatedResult.result -ne 'failure') {
            $aggregatedResult.result = 'partial'
        }
    }

    # Determine overall result based on aggregated data
    if ($aggregatedResult.failed -eq $ActionsToExecute.Count) {
        $aggregatedResult.result = 'failure'
    } elseif ($aggregatedResult.notCompleted -gt 0) {
        $aggregatedResult.result = 'partial'
    } else {
        $aggregatedResult.result = 'success'
    }

    if (-not $Suppress) {
        # Output the aggregated results
        $aggregatedResult
    }
}