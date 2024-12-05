function Add-AdobeGroupMember {
    <#
    .SYNOPSIS
    Adds a member to an Adobe group.

    .DESCRIPTION
    The Add-AdobeGroupMember cmdlet adds a specified user to one or more Adobe groups. It supports bulk processing for adding multiple groups at once.

    .PARAMETER GroupName
    The name(s) of the Adobe group(s) to which the user will be added.

    .PARAMETER Email
    The email address of the user to be added to the group(s).

    .PARAMETER BulkProcessing
    Enables bulk processing mode for adding multiple groups simultaneously.

    .EXAMPLE
    Add-AdobeGroupMember -GroupName "Admins" -Email "john.doe@example.com"

    .EXAMPLE
    Add-AdobeGroupMember -GroupName "Admins","Developers" -Email "john.doe@example.com" -BulkProcessing
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string[]] $GroupName,
        [Parameter(Mandatory)][string] $Email,
        [switch] $BulkProcessing
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
        requestID = "action_$(Get-Random)"
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

    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($GroupName, 'Add Adobe Group Member')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}