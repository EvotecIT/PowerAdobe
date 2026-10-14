BeforeAll {
    . (Join-Path $PSScriptRoot '../Private/Invoke-AdobeQuery.ps1')
    foreach ($name in @('Get-AdobeUser', 'Get-AdobeGroup', 'Get-AdobeGroupMember')) { . (Join-Path $PSScriptRoot "../Public/$name.ps1") }
    function Join-UriQuery { param($BaseUri, $RelativeOrAbsoluteUri, $QueryParameter) "$BaseUri/$RelativeOrAbsoluteUri" }
    function Invoke-WebRequest { [CmdletBinding()] param($Method, $Uri, $Headers) }
}

Describe 'Adobe GET pagination and strict failures' {
    BeforeEach {
        $script:AdobeTokenInformation = @{ Organization = 'synthetic'; Headers = @{} }
        $script:Requests = [Collections.Generic.List[string]]::new()
    }

    It 'reads all pages through <Command> without relying on JSON header fields' -ForEach @(
        @{ Command = 'Get-AdobeUser'; Arguments = @{}; Property = 'users' },
        @{ Command = 'Get-AdobeGroupMember'; Arguments = @{ GroupName = 'Example' }; Property = 'users' },
        @{ Command = 'Get-AdobeGroup'; Arguments = @{}; Property = 'groups' }
    ) {
        Mock Invoke-WebRequest {
            $script:Requests.Add([string] $Uri)
            $page = $script:Requests.Count - 1
            $body = @{ result = 'success'; lastPage = $page -eq 2 }
            $body[$Property] = @(@{ id = "page-$page" })
            [pscustomobject] @{ Content = ($body | ConvertTo-Json -Depth 6); Headers = @{ 'X-Page-Count' = '3' } }
        }
        $result = @(& $Command @Arguments -ErrorAction Stop)
        $result.id | Should -Be @('page-0', 'page-1', 'page-2')
        $script:Requests.Count | Should -Be 3
        $script:Requests[0] | Should -Match '/synthetic/0'
        $script:Requests[2] | Should -Match '/synthetic/2'
    }

    It 'terminates a strict caller on a failed later page without exposing the response or credential' {
        Mock Invoke-WebRequest {
            $script:Requests.Add([string] $Uri)
            if ($script:Requests.Count -eq 2) { throw 'synthetic-sensitive-provider-detail' }
            [pscustomobject] @{ Content = '{"lastPage":false,"result":"success","users":[{"id":"first"}]}' }
        }
        try { $result = @(Get-AdobeUser -ErrorAction Stop); throw 'Expected strict failure' }
        catch {
            $_.Exception.Message | Should -Match 'GET failed.*page 1.*complete result could not be retrieved'
            $_.Exception.Message | Should -Not -Match 'synthetic-sensitive-provider-detail'
        }
        $script:Requests.Count | Should -Be 2
    }

    It 'keeps warning and partial output for existing callers without ErrorAction Stop' {
        Mock Invoke-WebRequest {
            $script:Requests.Add([string] $Uri)
            if ($script:Requests.Count -eq 2) { throw 'request failed' }
            [pscustomobject] @{ Content = '{"lastPage":false,"result":"success","users":[{"id":"first"}]}' }
        }
        $result = @(Get-AdobeUser -ErrorAction Continue -WarningVariable notices -WarningAction SilentlyContinue)
        $result.id | Should -Be 'first'
        $notices | Should -HaveCount 1
        [string] $notices[0] | Should -Match 'complete result could not be retrieved'
    }

    It 'rejects <Case> before treating an invalid page as an empty tenant' -ForEach @(
        @{ Case = 'malformed JSON'; Content = 'synthetic-invalid-json' },
        @{ Case = 'unsuccessful API status'; Content = '{"result":"error.organization.invalid_id","message":"synthetic-sensitive-detail"}' },
        @{ Case = 'missing pagination state'; Content = '{"result":"success","users":[]}' },
        @{ Case = 'a string pagination flag'; Content = '{"lastPage":"true","result":"success","users":[]}' },
        @{ Case = 'a non-array page collection'; Content = '{"lastPage":true,"result":"success","users":"invalid"}' }
    ) {
        Mock Invoke-WebRequest { [pscustomobject] @{ Content = $Content } }
        { Get-AdobeUser -ErrorAction Stop } | Should -Throw '*complete result could not be retrieved*'
    }

    It 'returns an empty final page without emitting the response envelope' {
        Mock Invoke-WebRequest { [pscustomobject] @{ Content = '{"lastPage":true,"result":"success","users":[]}' } }
        @(Get-AdobeUser -ErrorAction Stop).Count | Should -Be 0
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly
    }

    It 'retrieves a single user once without requiring a pagination flag' {
        Mock Invoke-WebRequest { [pscustomobject] @{ Content = '{"result":"success","user":{"email":"user@example.test"}}' } }
        $result = @(Get-AdobeUser -Email 'user@example.test' -ErrorAction Stop)
        $result | Should -HaveCount 1
        $result[0].email | Should -Be 'user@example.test'
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter { $Uri -match '/users/user@example.test$' }
    }

    It 'does not treat missing authorization as empty data for <Command> in strict mode' -ForEach @(
        @{ Command = 'Get-AdobeUser'; Arguments = @{} },
        @{ Command = 'Get-AdobeGroup'; Arguments = @{} },
        @{ Command = 'Get-AdobeGroupMember'; Arguments = @{ GroupName = 'Example' } }
    ) {
        $script:AdobeTokenInformation = $null
        { & $Command @Arguments -ErrorAction Stop } | Should -Throw '*authorization is not available*'
    }
}
