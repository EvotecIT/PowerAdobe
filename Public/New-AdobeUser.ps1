function New-AdobeUser {
    <#
    .SYNOPSIS
    Creates a new Adobe user.

    .DESCRIPTION
    The New-AdobeUser cmdlet adds a new user to the Adobe system with specified details. It supports bulk processing and different user types.

    .PARAMETER EmailAddress
    The email address of the new user.

    .PARAMETER Country
    The country of the new user.

    .PARAMETER FirstName
    The first name of the new user.

    .PARAMETER LastName
    The last name of the new user.

    .PARAMETER Option
    Determines how to handle existing users. Options are 'ignoreIfAlreadyExists' or 'updateIfAlreadyExists'.

    .PARAMETER Type
    Specifies the type of Adobe ID to create. Valid values are 'createEnterpriseID', 'addAdobeID', or 'createFederatedID'.

    .PARAMETER BulkProcessing
    Switch to enable bulk processing mode.

    .EXAMPLE
    New-AdobeUser -EmailAddress "jane.doe@example.com" -Country "US" -FirstName "Jane" -LastName "Doe" -Type "createFederatedID"
    #>
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

