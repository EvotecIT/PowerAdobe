param([string] $ModuleRoot = (Join-Path $PSScriptRoot '../Artefacts/Unpacked/Modules/PowerAdobe'))
$ErrorActionPreference = 'Stop'
$env:PSModulePath = (Split-Path -Parent $ModuleRoot) + [IO.Path]::PathSeparator + (Join-Path $PSHOME 'Modules')
Import-Module (Join-Path $ModuleRoot 'PowerAdobe.psd1') -Force
$module = Get-Module PowerAdobe
& $module {
    $script:AdobeTokenInformation = @{ Organization = 'synthetic'; Headers = @{} }
    $script:Requests = 0
    $script:FailLaterPage = $false
    function script:Invoke-WebRequest {
        [CmdletBinding()] param($Method, $Uri, $Headers)
        $script:Requests++
        if ($script:FailLaterPage -and $script:Requests -eq 2) { throw 'synthetic-sensitive-detail' }
        $body = @{ result = 'success'; lastPage = $script:Requests -eq 3; users = @(@{ id = "page-$script:Requests" }) }
        [pscustomobject] @{ Content = ($body | ConvertTo-Json -Depth 5) }
    }
    $users = @(Get-AdobeUser -ErrorAction Stop)
    if ($users.Count -ne 3 -or $script:Requests -ne 3) { throw 'Actual package did not retrieve three pages' }
    $script:Requests = 0
    $script:FailLaterPage = $true
    $failed = $false
    try { $users = @(Get-AdobeUser -ErrorAction Stop) }
    catch {
        $failed = $_.Exception.Message -like '*page 1*complete result could not be retrieved*' -and $_.Exception.Message -notlike '*synthetic-sensitive-detail*'
    }
    if (-not $failed -or $script:Requests -ne 2) { throw 'Actual package strict retrieval contract failed' }
}
[pscustomobject] @{ Module = 'PowerAdobe'; Version = [string] $module.Version; PowerShell = [string] $PSVersionTable.PSVersion; Pagination = 'PASS'; StrictFailure = 'PASS'; ExternalCalls = 0 } | ConvertTo-Json
