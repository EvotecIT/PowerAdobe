function Set-AdobeGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][string] $NewName,
        [Parameter()][string] $Description
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

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($Name, 'Set Adobe Group')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}