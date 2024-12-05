function Set-AdobeGroup {
    <#
    .SYNOPSIS
    Updates an Adobe user group.

    .DESCRIPTION
    The Set-AdobeGroup cmdlet updates the name and/or description of an existing Adobe user group.

    .PARAMETER Name
    The current name of the Adobe group to update.

    .PARAMETER NewName
    The new name for the Adobe group.

    .PARAMETER Description
    The new description for the Adobe group.

    .PARAMETER BulkProcessing
    Switch to enable bulk processing mode.

    .EXAMPLE
    Set-AdobeGroup -Name "Developers" -NewName "Senior Developers" -Description "Group for senior developer roles"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][string] $NewName,
        [Parameter()][string] $Description,
        [switch] $BulkProcessing
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Set-AdobeGroup - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    if (-not $NewName -and -not $Description) {
        Write-Warning -Message 'Set-AdobeGroup - You need to provide either a new name or a description'
        return
    }

    $Data = [ordered] @{
        usergroup = $Name
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                'updateUserGroup' = [ordered] @{
                    name        = $NewName
                    description = $Description
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
        testOnly = if ($PSCmdlet.ShouldProcess($Name, 'Set Adobe Group')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}