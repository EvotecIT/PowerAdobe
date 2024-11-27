function Invoke-AdobeBulk {
    [CmdletBinding(supportsShouldProcess)]
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

    $ActionsToExecute | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess("Updates", 'Do bulk updates')) { $false } else { $true }
    }

    $Output = Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $ActionsToExecute -QueryParameter $QueryParameter
    if ($Output) {
        foreach ($ErrorMessage in $Output.Errors) {
            Write-Warning -Message "Invoke-AdobeBulk - Processing error [user: $($ErrorMessage.User), index: $($ErrorMessage.Index)] - $($ErrorMessage.Message)"
        }
        if ($Suppress) {
            return
        }
        $Output
    }
}