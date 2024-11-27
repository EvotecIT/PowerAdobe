function Invoke-AdobeQuery {
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
        $UsedUrl = $Url
        Do {
            $UsedUrl = $Url.Replace('{orgId}', $Organization)
            $UsedUrl = $UsedUrl.Replace('{page}', $Page)
            $UriToUse = Join-UriQuery -BaseUri $BaseUri -RelativeOrAbsoluteUri $UsedUrl -QueryParameter $QueryParameter

            Write-Verbose -Message "Invoke-AdobeQuery - Url: $UriToUse / Method: $Method / Page: $Page"
            try {
                $Response = $null
                $Response = Invoke-WebRequest -Method Get -Uri $UriToUse -Headers $Script:AdobeTokenInformation.Headers -ErrorAction Stop -Verbose:$false
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
            if ($Response) {
                $Output = $Response.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($null -ne $Output.users) {
                    $Output.users
                } elseif ($null -ne $Output.groups) {
                    $Output.groups
                } elseif ($null -ne $Output.user) {
                    $Output.user
                } else {
                    $Output
                }
                if ($Output.Headers."-X-Page-Count") {
                    $MaximumPageCount = $Output.Headers."-X-Page-Count"
                }
            } else {
                Write-Warning -Message "Invoke-AdobeQuery - Unable to connect to organization '$Organization'. Terminating"
                break
            }
            $Page++
        } while (-not $Output.LastPage -and $Page -le $MaximumPageCount)
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