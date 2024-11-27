function Get-AdobeUser {
    <#
    .SYNOPSIS
    Retrieves Adobe user information.

    .DESCRIPTION
    The Get-AdobeUser cmdlet fetches details of a specific Adobe user or lists all users if no email is provided. Requires an active Adobe connection.

    .PARAMETER Email
    The email address of the user to retrieve information for.

    .EXAMPLE
    Get-AdobeUser -Email "jane.doe@example.com"

    .EXAMPLE
    Get-AdobeUser
    #>
    [CmdletBinding()]
    param(
        [string] $Email
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Get-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    if ($Email) {
        #Get user information : GET /v2/usermanagement/organizations/{orgId}/users/{userString}
        Invoke-AdobeQuery -Url "organizations/{orgId}/users/$Email" -Method 'GET'
    } else {
        #List all users : GET /v2/usermanagement/users/{orgId}/{page}
        Invoke-AdobeQuery -Url "users/{orgId}/{page}" -Method 'GET'
    }
}