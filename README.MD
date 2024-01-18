

## Throttling Limits
To protect the availability of the Adobe back-end user identity systems, the User Management API imposes limits on client access to the data.
Limits apply to the number of calls that an individual client can make within a time interval,
and global limits apply to access by all clients within the time period. For this API the throttling limits are as follows:

- Maximum calls per client: 25 requests per a minute
- Maximum calls for the application: 100 requests per a minute

When the client or global access limit is reached, further calls fail with HTTP error status 429 Too Many Requests.
The Retry-After header is included in the 429 response, and provides the minimum amount of time that the client should wait until retrying.
See RFC 7231 for full information.

The User Management API recommends limiting your syncs to two hourly intervals and consider scheduling your sync
for a time that works best for you, taking into account other timezones and clients.
This will help to prevent how often your client is throttled.