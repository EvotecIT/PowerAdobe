function Get-AdobeGroup {
    [CmdletBinding()]
    param(

    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Get-AdobeGroup - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    Invoke-AdobeQuery -Url "groups" -Method 'GET'
}