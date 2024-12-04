function New-AdobeGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][string] $Description,
        [ValidateSet('ignoreIfAlreadyExists', 'updateIfAlreadyExists')]
        [string] $Option = 'ignoreIfAlreadyExists',
        [switch] $BulkProcessing
    )

    $OptionList = @{
        ignoreIfAlreadyExists = 'ignoreIfAlreadyExists'
        updateIfAlreadyExists = 'updateIfAlreadyExists'
    }
    $OptionConverted = $OptionList[$Option]

    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Get-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    $Data = [ordered] @{
        usergroup = $Name
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                'createUserGroup' = [ordered] @{
                    name        = $Name
                    description = $Description
                    option      = $OptionConverted
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
        testOnly = if ($PSCmdlet.ShouldProcess($Name, 'Create Adobe Group')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}