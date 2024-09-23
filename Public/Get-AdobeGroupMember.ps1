function Get-AdobeGroupMember {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)][string] $GroupName
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Get-AdobeGroup - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    Invoke-AdobeQuery -Url "users/{orgId}/{page}/$GroupName" -Method 'GET'
}