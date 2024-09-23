function Remove-AdobeGroupMember {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string[]] $GroupName,
        [Parameter(Mandatory)][string] $Email,
        [switch] $All
    )

    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Remove-AdobeGroupMember - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    if ($GroupName.Count -gt 10) {
        Write-Warning -Message 'Remove-AdobeGroupMember - Only ten groups can be added at a time'
        return
    }
    if ($All) {
        $Data = [ordered] @{
            user      = $Email
            requestID = "action_1"
            do        = @(
                @{
                    'remove' = 'all'
                }
            )
        }
    } else {
        $Data = [ordered] @{
            user      = $Email
            requestID = "action_1"
            do        = @(
                @{
                    'remove' = @{
                        'group' = @(
                            $GroupName
                        )
                    }
                }
            )
        }
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($GroupName, 'Remove Adobe Group Member')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}