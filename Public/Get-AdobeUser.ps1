function Get-AdobeUser {
    [CmdletBinding()]
    param(

    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Get-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    $Page = 0
    Do {
        $Url = "https://usermanagement.adobe.io/v2/usermanagement/users/$($($Script:AdobeTokenInformation).Organization)/$Page"

        Write-Verbose -Message "Get-AdobeUser - Url: $Url"

        try {
            #$Output = Invoke-RestMethod -Method Get -Uri $Url -Headers $Script:AdobeTokenInformation.Headers -ErrorAction Stop -Verbose:$false
            $Response = Invoke-WebRequest -Method Get -Uri $Url -Headers $Script:AdobeTokenInformation.Headers -ErrorAction Stop -Verbose:$false
        } catch {
            if ($_.Exception.Response.StatusCode -eq 'TooManyRequests') {
                $TimeToRetry = $_.Exception.Response.Headers.RetryAfter
                Write-Warning -Message "Get-AdobeUser - Too many requests. Retry after $TimeToRetry seconds"
            } else {
                if ($_.ErrorDetails.Message) {
                    try {
                        $ErrorCode = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Stop
                        Write-Warning -Message "Get-AdobeUser - Unable to connect to organization '$Organization'. Error code $($ErrorCode.error_Code) / $($ErrorCode.message)"
                    } catch {
                        Write-Warning -Message "Get-AdobeUser - Unable to connect to organization '$Organization'. Error $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning -Message "Get-AdobeUser - Unable to connect to organization '$Organization'. Error $($_.Exception.Message)"
                }
            }
        }
        $Output = $Response.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($Output.users) {
            $Output.users
        }
        if ($Output.Headers."-X-Page-Count") {
            $MaximumPageCount = $Output.Headers."-X-Page-Count"
        }
        $Page++
    } while (-not $Output.LastPage -and $Page -le $MaximumPageCount)
}