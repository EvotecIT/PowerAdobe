function Add-AdobeGroupMember {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string[]] $GroupName,
        [Parameter(Mandatory)][string] $Email
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Add-AdobeGroupMember - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    if ($GroupName.Count -gt 10) {
        Write-Warning -Message 'Add-AdobeGroupMember - Only ten groups can be added at a time'
        return
    }
    $Data = [ordered] @{
        user      = $Email
        requestID = "action_1"
        do        = @(
            @{
                'add' = @{
                    'group' = @(
                        $GroupName
                    )
                }
            }
        )
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($GroupName, 'Add Adobe Group Member')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}