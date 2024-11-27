function Remove-AdobeGroup {
    <#
    .SYNOPSIS
    Removes an Adobe user group.

    .DESCRIPTION
    The Remove-AdobeGroup cmdlet deletes a specified user group from the Adobe system. It requires an active Adobe connection.

    .PARAMETER Name
    The name of the Adobe group to remove.

    .EXAMPLE
    Remove-AdobeGroup -Name "MarketingTeam"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [alias('GroupName')][Parameter(Mandatory)][string] $Name
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Remove-AdobeGroup - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    $Data = [ordered] @{
        usergroup = $Name
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                'deleteUserGroup' = [ordered] @{ }
            }
        )
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($Name, 'Remove Adobe Group Member')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}