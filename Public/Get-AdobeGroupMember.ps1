function Get-AdobeGroupMember {
    <#
    .SYNOPSIS
    Retrieves members of a specified Adobe group.

    .DESCRIPTION
    The Get-AdobeGroupMember cmdlet fetches all members belonging to a specific group within the Adobe system. Requires an active Adobe connection.

    .PARAMETER GroupName
    The name of the group to retrieve members for.

    .EXAMPLE
    Get-AdobeGroupMember -GroupName "Admins"
    #>
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