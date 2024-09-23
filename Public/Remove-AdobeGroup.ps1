function Remove-AdobeGroup {
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
        requestID = "action_1"
        do        = @(
            [ordered] @{
                'deleteUserGroup' = [ordered] @{}
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