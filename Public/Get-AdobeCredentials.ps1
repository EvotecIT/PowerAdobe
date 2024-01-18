function Get-AdobeCredentials {
    [CmdletBinding()]
    param(

    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Get-AdobeCredentials - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    $Url = "https://api.adobe.io/console/organizations/$($($Script:AdobeTokenInformation).Organization)/credentials"

    Write-Verbose -Message "Get-AdobeCredentials - Url: $Url"
    try {
        Invoke-RestMethod -Method Get -Uri $Url -Headers $Script:AdobeTokenInformation.Headers -ErrorAction Stop -Verbose:$false
    } catch {
        try {
            $ErrorCode = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Stop
            Write-Warning -Message "Get-AdobeCredentials - Unable to connect to organization '$Organization'. Error code $($ErrorCode.error_Code) / $($ErrorCode.message)"
        } catch {
            Write-Warning -Message "Get-AdobeCredentials - Unable to connect to organization '$Organization'. Error $($_.Exception.Message)"
        }
    }
}