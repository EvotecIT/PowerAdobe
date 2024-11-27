function New-AdobeUser {
    [Alias('Add-AdobeUser')]
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [string] $EmailAddress,
        [string] $Country,
        [string] $FirstName,
        [string] $LastName,

        [ValidateSet('ignoreIfAlreadyExists', 'updateIfAlreadyExists')]
        [string] $Option = 'ignoreIfAlreadyExists',

        [Parameter(Mandatory)]
        [ValidateSet('createEnterpriseID', 'addAdobeID', 'createFederatedID')]
        [string] $Type,
        [switch] $BulkProcessing
    )

    $List = @{
        createEnterpriseID = 'createEnterpriseID'
        addAdobeID         = 'addAdobeID'
        createFederatedID  = 'createFederatedID'
    }
    $OptionList = @{
        ignoreIfAlreadyExists = 'ignoreIfAlreadyExists'
        updateIfAlreadyExists = 'updateIfAlreadyExists'
    }
    $OptionConverted = $OptionList[$Option]

    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'New-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    # we need to convert the type to the correct format so it preservers problem casing
    $ConvertedType = $List[$Type]
    $Data = [ordered] @{
        user      = $EmailAddress
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                $ConvertedType = [ordered] @{
                    email     = $EmailAddress
                    country   = $Country
                    firstname = $FirstName
                    lastname  = $LastName
                    option    = $OptionConverted
                }
            }
        )
    }
    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($EmailAddress, 'Add Adobe User')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}

