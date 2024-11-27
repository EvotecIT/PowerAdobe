function Get-AdobeGroup {
    <#
    .SYNOPSIS
    Retrieves Adobe groups.

    .DESCRIPTION
    The Get-AdobeGroup cmdlet lists all user groups within the Adobe system. It requires an active Adobe connection.

    .EXAMPLE
    Get-AdobeGroup
    #>
    [CmdletBinding()]
    param(

    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Get-AdobeGroup - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    Invoke-AdobeQuery -Url "groups/{orgId}/{page}" -Method 'GET'
}