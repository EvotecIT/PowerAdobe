@{
    AliasesToExport        = @('Add-AdobeUser')
    Author                 = 'Przemyslaw Klys'
    CmdletsToExport        = @()
    CompanyName            = 'Evotec'
    CompatiblePSEditions   = @('Desktop', 'Core')
    Copyright              = '(c) 2011 - 2026 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description            = 'PowerAdobe is an unofficial PowerShell module for Adobe API.'
    FunctionsToExport      = @('Add-AdobeGroupMember', 'Connect-Adobe', 'Get-AdobeGroup', 'Get-AdobeGroupMember', 'Get-AdobeUser', 'Invoke-AdobeBulk', 'New-AdobeGroup', 'New-AdobeUser', 'Remove-AdobeGroup', 'Remove-AdobeGroupMember', 'Remove-AdobeUser', 'Set-AdobeGroup', 'Set-AdobeUser')
    GUID                   = 'c2607b7b-4422-4687-b22c-1c26b456b47c'
    ModuleVersion          = '1.0.6'
    PowerShellVersion      = '5.1'
    PrivateData            = @{
        PSData = @{
            ProjectUri = 'https://github.com/EvotecIT/PowerAdobe'
            Tags       = @('Windows', 'MacOS', 'Linux')
            RequireLicenseAcceptance = $false
            ExternalModuleDependencies = @()
}
    }
    RootModule             = 'PowerAdobe.psm1'
    RequiredModules      = @()
}