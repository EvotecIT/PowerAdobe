# PowerAdobe - Adobe User Management PowerShell Module

<p align="center">
  <a href="https://www.powershellgallery.com/packages/PowerAdobe"><img src="https://img.shields.io/powershellgallery/v/PowerAdobe.svg?style=flat-square"></a>
  <a href="https://www.powershellgallery.com/packages/PowerAdobe"><img src="https://img.shields.io/powershellgallery/vpre/PowerAdobe.svg?label=powershell%20gallery%20preview&colorB=yellow&style=flat-square"></a>
  <a href="https://github.com/EvotecIT/PowerAdobe"><img src="https://img.shields.io/github/license/EvotecIT/PowerAdobe.svg?style=flat-square"></a>
</p>

<p align="center">
  <a href="https://www.powershellgallery.com/packages/PowerAdobe"><img src="https://img.shields.io/powershellgallery/p/PowerAdobe.svg?style=flat-square"></a>
  <a href="https://github.com/EvotecIT/PowerAdobe"><img src="https://img.shields.io/github/languages/top/evotecit/PowerAdobe.svg?style=flat-square"></a>
  <a href="https://github.com/EvotecIT/PowerAdobe"><img src="https://img.shields.io/github/languages/code-size/evotecit/PowerAdobe.svg?style=flat-square"></a>
  <a href="https://www.powershellgallery.com/packages/PowerAdobe"><img src="https://img.shields.io/powershellgallery/dt/PowerAdobe.svg?style=flat-square"></a>
</p>

<p align="center">
  <a href="https://twitter.com/PrzemyslawKlys"><img src="https://img.shields.io/twitter/follow/PrzemyslawKlys.svg?label=Twitter%20%40PrzemyslawKlys&style=flat-square&logo=twitter"></a>
  <a href="https://evotec.xyz/hub"><img src="https://img.shields.io/badge/Blog-evotec.xyz-2A6496.svg?style=flat-square"></a>
  <a href="https://www.linkedin.com/in/pklys"><img src="https://img.shields.io/badge/LinkedIn-pklys-0077B5.svg?logo=LinkedIn&style=flat-square"></a>
</p>

`PowerAdobe` is a PowerShell module that allows you to interact with Adobe User Management API. It's a simple module that allows you to get information about users, groups, and more

## Installation

```powershell
Install-Module -Name PowerAdobe -Force -Verbose
```

## Available commands

| CommandType | Name                    | Version | Source     |
| ----------- | ----------------------- | ------- | ---------- |
| Alias       | Add-AdobeUser           | 0.0.0   | PowerAdobe |
| Function    | Add-AdobeGroupMember    | 0.0.0   | PowerAdobe |
| Function    | Connect-Adobe           | 0.0.0   | PowerAdobe |
| Function    | Get-AdobeCredentials    | 0.0.0   | PowerAdobe |
| Function    | Get-AdobeGroup          | 0.0.0   | PowerAdobe |
| Function    | Get-AdobeGroupMember    | 0.0.0   | PowerAdobe |
| Function    | Get-AdobeUser           | 0.0.0   | PowerAdobe |
| Function    | New-AdobeGroup          | 0.0.0   | PowerAdobe |
| Function    | New-AdobeUser           | 0.0.0   | PowerAdobe |
| Function    | Remove-AdobeGroup       | 0.0.0   | PowerAdobe |
| Function    | Remove-AdobeGroupMember | 0.0.0   | PowerAdobe |
| Function    | Remove-AdobeUser        | 0.0.0   | PowerAdobe |
| Function    | Set-AdobeGroup          | 0.0.0   | PowerAdobe |
| Function    | Set-AdobeUser           | 0.0.0   | PowerAdobe |

## Examples

```powershell
# Keep in mind of thresholds which are very strict for all users (1-2 calls per hour regardless of how many users you have)
$Users = Get-AdobeUser
$Users | Format-Table

$User = Get-AdobeUser -Email '<email>' -Verbose
$User | Format-Table

# Keep in mind of thresholds which are very strict for all groups (1-2 calls per hour regardless of how many users you have)
$Groups = Get-AdobeGroup -Verbose
$Groups | Format-Table

$GroupMembers = Get-AdobeGroupMember -GroupName 'Admins' -Verbose
$GroupMembers | Format-Table

$NewGroup = New-AdobeGroup -Name 'TestGroup2' -Description 'Test Group Description'
$NewGroup | Format-Table

$UpdateGroup = Set-AdobeGroup -Name 'TestGroup2' -NewName 'TestGroup3' -Description 'Test Group Description 3' -Verbose
$UpdateGroup | Format-Table

$ActionInformation = Add-AdobeUser -EmailAddress 'JZ@test.com' -Country 'PL' -FirstName 'Przemyslaw' -LastName 'Klys' -Option ignoreIfAlreadyExists -Type createFederatedID -WhatIf -Verbose
$ActionInformation

$SetInformaiton = Set-AdobeUser -EmailAddress 'JZ@test.com' -LastName 'Klys' -WhatIf -Verbose
$SetInformaiton
```

## User Management API

User management API: https://adobe-apiplatform.github.io/umapi-documentation/en/api/user.html

| Action                                       | Method                                                          | Description                                                                                                                                                                                                                                                                                                                                                                       |
| -------------------------------------------- | --------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Get User Information                         | GET /v2/usermanagement/organizations/{orgId}/users/{userString} | Retrieves the details of a single user within a specified organization, identified by email address or username and domain. Successful queries return a 200 response whose body is a single JSON structure containing the user information.                                                                                                                                       |
| Get Users in Organization                    | GET /v2/usermanagement/users/{orgId}/{page}                     | Retrieve a paged list of all users in your organization along with information about them. The number of users returned in each call is subject to change, currently the limit is max 2000 entries/page. You can make multiple paginated calls to retrieve the full list of users. The domain query parameter filters the results to only return users within a specified domain. |
| Get Users in a User Group or Product Profile | GET /v2/usermanagement/users/{orgId}/{page}/{groupName}         | Gets a paged list of users in a specific group of an organization along with information about them. Groups can be named user groups, product profiles, or group-specific administrative groups.                                                                                                                                                                                  |
| Get User Groups and Product Profiles         | GET /v2/usermanagement/groups/{orgId}/{page}                    | Retrieves a paged list of all user groups and product profiles in your organization along with information about them. You can make multiple paginated calls to retrieve the full list.                                                                                                                                                                                           |

## Throttling Limits

To protect the availability of the Adobe back-end user identity systems, the User Management API imposes limits on client access to the data.
Limits apply to the number of calls that an individual client can make within a time interval,
and global limits apply to access by all clients within the time period.

When the client or global access limit is reached, further calls fail with HTTP error status 429 Too Many Requests.
The Retry-After header is included in the 429 response, and provides the minimum amount of time that the client should wait until retrying.
See RFC 7231 for full information.

The User Management API recommends limiting your syncs to two hourly intervals and consider scheduling your sync
for a time that works best for you, taking into account other timezones and clients.
This will help to prevent how often your client is throttled.

### User Management Action API

Maximum calls per client: 10 requests per a minute
Maximum calls for the application: 100 requests per a minute

### User Access API

Maximum calls per client: 25 requests per a minute
Maximum calls for the application: 100 requests per a minute

### Groups Access API

Maximum calls per client: 5 requests per a minute
Maximum calls for the application: 100 requests per a minute

### User / Groups API Limits
If you are querying all users/all groups different limits apply. Basically 1-2 calls per hour are allowed and if you exceed this limit you will be throttled right away.
Use with caution as Adobe is very strict with their API limits.