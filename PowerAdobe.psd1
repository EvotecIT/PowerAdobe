@{
    AliasesToExport        = @('Add-AdobeUser')
    Author                 = 'Przemyslaw Klys'
    CmdletsToExport        = @()
    CompanyName            = 'Evotec'
    CompatiblePSEditions   = @('Desktop', 'Core')
    Copyright              = '(c) 2011 - 2024 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description            = 'PowerAdobe is an unofficial PowerShell module for Adobe API.'
    DotNetFrameworkVersion = '4.5.2'
    FunctionsToExport      = @('Add-AdobeGroupMember', 'Connect-Adobe', 'Get-AdobeCredentials', 'Get-AdobeGroup', 'Get-AdobeGroupMember', 'Get-AdobeUser', 'New-AdobeGroup', 'New-AdobeUser', 'Remove-AdobeGroup', 'Remove-AdobeGroupMember', 'Remove-AdobeUser', 'Set-AdobeGroup', 'Set-AdobeUser')
    GUID                   = 'c2607b7b-4422-4687-b22c-1c26b456b47c'
    ModuleVersion          = '0.0.0'
    PowerShellVersion      = '5.1'
    PrivateData            = @{
        PSData = @{
            ExternalModuleDependencies = @('Microsoft.PowerShell.Utility', 'Microsoft.PowerShell.Security')
            ProjectUri                 = 'https://github.com/EvotecIT/PowerAdobe'
            Tags                       = @('Windows', 'MacOS', 'Linux')
        }
    }
    RequiredModules        = @('Microsoft.PowerShell.Utility', 'Microsoft.PowerShell.Security')
    RootModule             = 'PowerAdobe.psm1'
}