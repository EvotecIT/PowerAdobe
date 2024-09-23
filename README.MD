

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


# Url:

https://adobe-apiplatform.github.io/umapi-documentation/en/api/user.html


List all users : GET /v2/usermanagement/users/{orgId}/{page}
Get user information : GET /v2/usermanagement/organizations/{orgId}/users/{userString}
Get all member users in a group : GET /v2/usermanagement/users/{orgId}/{page}/{groupName}

GET /v2/usermanagement/users/{orgId}/{page}
GET /v2/usermanagement/users/{orgId}/{page}/{groupName}
GET /v2/usermanagement/groups/{orgId}/{page}


Get User Information
GET /v2/usermanagement/organizations/{orgId}/users/{userString}
Retrieves the details of a single user within a specified organization, identified by email address or username and domain. Successful queries return a 200 response whose body is a single JSON structure containing the user information.

Get Users in Organization
GET /v2/usermanagement/users/{orgId}/{page}
Retrieve a paged list of all users in your organization along with information about them. The number of users returned in each call is subject to change, currently the limit is max 2000 entries/page. You can make multiple paginated calls to retrieve the full list of users. The domain query parameter filters the results to only return users within a specified domain.

Get Users in a User Group or Product Profile
GET /v2/usermanagement/users/{orgId}/{page}/{groupName}
Gets a paged list of users in a specific group of an organization along with information about them. Groups can be named user groups, product profiles, or group-specific administrative groups.

Get User Groups and Product Profiles
GET /v2/usermanagement/groups/{orgId}/{page}
Retrieves a paged list of all user groups and product profiles in your organization along with information about them. You can make multiple paginated calls to retrieve the full list.