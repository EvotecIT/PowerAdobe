function Remove-AdobeGroupMember {
    <#
    .SYNOPSIS
    Removes a member from one or more Adobe groups.

    .DESCRIPTION
    The Remove-AdobeGroupMember cmdlet removes a specified user from one or more Adobe groups. Use the -All switch to remove the user from all groups.

    .PARAMETER GroupName
    The name(s) of the Adobe group(s) from which the user will be removed.

    .PARAMETER Email
    The email address of the user to be removed from the group(s).

    .PARAMETER All
    Removes the user from all Adobe groups.

    .EXAMPLE
    Remove-AdobeGroupMember -GroupName "Marketing" -Email "user@example.com"

    .EXAMPLE
    Remove-AdobeGroupMember -All -Email "user@example.com"
    #>
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
            requestID = "action_$(Get-Random)"
            do        = @(
                @{
                    'remove' = 'all'
                }
            )
        }
    } else {
        $Data = [ordered] @{
            user      = $Email
            requestID = "action_$(Get-Random)"
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