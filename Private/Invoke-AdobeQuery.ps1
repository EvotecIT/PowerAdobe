function Invoke-AdobeQuery {
    <#
    .SYNOPSIS
    Executes a query against the Adobe User Management API.

    .DESCRIPTION
    The Invoke-AdobeQuery function sends HTTP requests to the Adobe User Management API. It handles GET and other HTTP methods, manages pagination, and processes responses.

    .PARAMETER BaseUri
    The base URI for the Adobe User Management API. Defaults to 'https://usermanagement.adobe.io/v2/usermanagement'.

    .PARAMETER Url
    The endpoint URL for the specific API call.

    .PARAMETER Method
    The HTTP method to use for the request (e.g., GET, POST).

    .PARAMETER Data
    The data to include in the body of the request, applicable for methods like POST.

    .PARAMETER QueryParameter
    Additional query parameters to include in the request URI.

    .EXAMPLE
    Invoke-AdobeQuery -Url "users" -Method "GET"

    .EXAMPLE
    Invoke-AdobeQuery -Url "groups" -Method "POST" -Data $groupData
    #>
    [CmdletBinding()]
    param(
        [string] $BaseUri = 'https://usermanagement.adobe.io/v2/usermanagement',
        [Parameter(Mandatory)][string] $Url,
        [Parameter(Mandatory)][string] $Method,
        [Parameter()][System.Collections.IDictionary[]] $Data,
        [Parameter()][System.Collections.IDictionary] $QueryParameter
    )
    $Organization = $($($Script:AdobeTokenInformation).Organization)
    if ($Method -eq 'GET') {
        $Page = 0
        $Paged = $Url.Contains('{page}')
        $Strict = $ErrorActionPreference -eq [System.Management.Automation.ActionPreference]::Stop
        do {
            $UsedUrl = $Url.Replace('{orgId}', $Organization).Replace('{page}', [string] $Page)
            $UriToUse = Join-UriQuery -BaseUri $BaseUri -RelativeOrAbsoluteUri $UsedUrl -QueryParameter $QueryParameter
            Write-Verbose -Message "Invoke-AdobeQuery - Url: $UriToUse / Method: $Method / Page: $Page"
            try {
                $Response = Invoke-WebRequest -Method Get -Uri $UriToUse -Headers $Script:AdobeTokenInformation.Headers -ErrorAction Stop -Verbose:$false
                if (-not $Response -or [string]::IsNullOrWhiteSpace($Response.Content)) { throw 'Adobe returned an empty response.' }
                $Output = $Response.Content | ConvertFrom-Json -ErrorAction Stop
                if ($Output -isnot [System.Management.Automation.PSCustomObject]) { throw 'Adobe returned an invalid response object.' }
                if ($Output.result -and $Output.result -ne 'success') { throw 'Adobe reported an unsuccessful result.' }
                if ($Paged -and ($Output.lastPage -isnot [bool] -or (-not $Output.PSObject.Properties['users'] -and -not $Output.PSObject.Properties['groups']))) {
                    throw 'Adobe returned an invalid paged response.'
                }
                if ($Paged -and (($Output.PSObject.Properties['users'] -and $Output.users -isnot [array]) -or ($Output.PSObject.Properties['groups'] -and $Output.groups -isnot [array]))) { throw 'Adobe returned an invalid page collection.' }
            } catch {
                $Message = "Invoke-AdobeQuery - GET failed for organization '$Organization' at page $Page. A complete result could not be retrieved. Check authentication, service availability, and the response format."
                if ($Strict) { throw $Message }
                Write-Warning -Message $Message
                return
            }
            if ($null -ne $Output.PSObject.Properties['users']) { $Output.users }
            elseif ($null -ne $Output.PSObject.Properties['groups']) { $Output.groups }
            elseif ($null -ne $Output.PSObject.Properties['user']) { $Output.user }
            else { $Output }
            $Page++
        } while ($Paged -and -not $Output.lastPage)
    } else {
        $UriToUse = Join-UriQuery -BaseUri $BaseUri -RelativeOrAbsoluteUri "$Url/$Organization" -QueryParameter $QueryParameter

        Write-Verbose -Message "Invoke-AdobeQuery - Url: $UriToUse / Method: $Method"
        try {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $DataJSON = @($Data) | ConvertTo-JsonLiteral -Depth 5 -AsArray
            } else {
                $DataJSON = @($Data) | ConvertTo-Json -Depth 5 -AsArray
            }
            $Response = Invoke-WebRequest -Method $Method -Uri $UriToUse -Headers $Script:AdobeTokenInformation.Headers -ErrorAction Stop -Verbose:$false -Body $DataJSON
        } catch {
            if ($_.Exception.Response.StatusCode -eq 'TooManyRequests') {
                $TimeToRetry = $_.Exception.Response.Headers.RetryAfter
                Write-Warning -Message "Invoke-AdobeQuery - Too many requests. Retry after $TimeToRetry seconds"
            } else {
                $ErrorDetails = $_.ErrorDetails
                if ($_.ErrorDetails.Message) {
                    try {
                        $Message = $_.Exception.Message
                        $ErrorCode = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Stop
                        if ($ErrorCode) {
                            Write-Warning -Message "Invoke-AdobeQuery - Unable to connect to organization '$Organization'. Error code $($ErrorCode.error_Code) / $($ErrorCode.message)"
                        } else {
                            Write-Warning -Message "Invoke-AdobeQuery - Unable to connect to organization '$Organization'. Error $Message"
                        }
                    } catch {
                        Write-Warning -Message "Invoke-AdobeQuery - Unable to connect to organization '$Organization'. Error $($_.Exception.Message), ErrorDetails: $($ErrorDetails.Message)"
                    }
                } else {
                    Write-Warning -Message "Invoke-AdobeQuery - Unable to connect to organization '$Organization'. Error $($_.Exception.Message), ErrorDetails: $($ErrorDetails.Message)"
                }
            }
        }
        if ($Response -and $Response.Content) {
            $Output = $Response.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
            $Output
        } elseif ($Response) {
            $Response
        }
    }
}
