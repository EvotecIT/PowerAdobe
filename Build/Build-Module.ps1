param(
    [Alias('RunMode')]
    [ValidateSet('Manifest', 'Build', 'Publish')]
    [string] $ConfigurationGateMode = 'Build',
    [bool] $SignModule = $true,
    [switch] $SkipInstall,
    [string] $PackageRoot = 'Artefacts',
    [string] $CertificateThumbprint = '92E95FB58EFFA6A4A75E77A33CDD6BFE6DD30F1A',
    [string] $PowerShellGalleryApiKeyPath = (Join-Path $HOME '.config/evotec/psgallery-api-key.txt'),
    [string] $GitHubApiKeyPath = (Join-Path $HOME '.config/evotec/github-api-key.txt')
)

Import-Module PSPublishModule -MinimumVersion 3.0.169 -Force -ErrorAction Stop

Build-Module -ModuleName 'PowerAdobe' {
    New-ConfigurationManifest -ModuleVersion '1.0.6' -CompatiblePSEditions Desktop, Core `
        -Guid 'c2607b7b-4422-4687-b22c-1c26b456b47c' -Author 'Przemyslaw Klys' -CompanyName Evotec `
        -Copyright "(c) 2011 - $((Get-Date).Year) Przemyslaw Klys @ Evotec. All rights reserved." `
        -Description 'PowerAdobe is an unofficial PowerShell module for Adobe API.' -PowerShellVersion '5.1' `
        -Tags Windows, macOS, Linux, Adobe -ProjectUri 'https://github.com/EvotecIT/PowerAdobe'
    New-ConfigurationGate -Mode $ConfigurationGateMode
    New-ConfigurationModule -Type RequiredModule -Name PSSharedGoods -Guid Auto -RequiredVersion '0.0.313' -VersionSource PSGallery
    New-ConfigurationModule -Type ApprovedModule -Name PSSharedGoods, PSWriteColor
    New-ConfigurationModuleSkip -IgnoreFunctionName IsOfType, IsNumeric -IgnoreModuleName Microsoft.PowerShell.Utility, Microsoft.PowerShell.Management, Microsoft.PowerShell.Security
    New-ConfigurationFormat -ApplyTo OnMergePSM1, OnMergePSD1 -EnableFormatting -PSD1Style Minimal
    New-ConfigurationImportModule -ImportSelf -ImportRequiredModules
    New-ConfigurationTest -TestsPath 'Tests' -Enable
    New-ConfigurationBuild -Enable -SignModule:$SignModule -CertificateThumbprint $CertificateThumbprint -MergeModuleOnBuild -MergeFunctionsFromApprovedModules -LocalVersioning:$false
    New-ConfigurationArtefact -Type Unpacked -Enable -Path (Join-Path $PackageRoot 'Unpacked') -ModulesPath Modules -RequiredModulesPath Modules -AddRequiredModules
    New-ConfigurationArtefact -Type Packed -Enable -Path (Join-Path $PackageRoot 'Packed') -ArtefactName '<ModuleName>.v<ModuleVersion>.zip'
    New-ConfigurationPublish -Type PowerShellGallery -FilePath $PowerShellGalleryApiKeyPath -Enabled
    New-ConfigurationPublish -Type GitHub -FilePath $GitHubApiKeyPath -UserName EvotecIT -RepositoryName 'PowerAdobe' -GenerateReleaseNotes -Enabled
} -SkipInstall:$SkipInstall -NoInteractive -ExitCode
