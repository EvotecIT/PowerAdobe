function Get-AdobeUser {
    [CmdletBinding()]
    param(

    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Get-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    Invoke-AdobeQuery -Url "users" -Method 'GET'
}