function Remove-AdobeUser {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $EmailAddress,
        [switch] $DoNotDeleteAccount
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Remove-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    $Data = [ordered] @{
        user      = $EmailAddress
        requestID = "action_1"
        do        = @(
            [ordered] @{
                'removeFromOrg' = [ordered] @{
                    deleteAccount = -not $DoNotDeleteAccount.IsPresent
                }
            }
        )
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($EmailAddress, 'Remove Adobe User')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}