function Remove-AdobeUser {
    <#
    .SYNOPSIS
    Removes an Adobe user.

    .DESCRIPTION
    The Remove-AdobeUser cmdlet deletes a specified user from the Adobe system. Optionally, it can also delete the user's account.

    .PARAMETER EmailAddress
    The email address of the Adobe user to remove.

    .PARAMETER DoNotDeleteAccount
    When specified, the user's account will not be deleted, only their association with groups.

    .PARAMETER BulkProcessing
    Switch to enable bulk processing mode.

    .EXAMPLE
    Remove-AdobeUser -EmailAddress "jane.doe@example.com" -DoNotDeleteAccount
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $EmailAddress,
        [switch] $DoNotDeleteAccount,
        [switch] $BulkProcessing
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Remove-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    $Data = [ordered] @{
        user      = $EmailAddress
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                'removeFromOrg' = [ordered] @{
                    deleteAccount = -not $DoNotDeleteAccount.IsPresent
                }
            }
        )
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($EmailAddress, 'Remove Adobe User')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}