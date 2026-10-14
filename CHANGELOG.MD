### 1.0.6 - 2026-10-14

- Keep generated ZIPs and unpacked modules out of source control; build and release commands generate them locally.
- Standardize native Manifest, Build and Publish modes, retain the RunMode alias and add CI checks for source tests and packaged behavior on PowerShell 5.1 and 7.

- Retrieve all user, group-member, and group pages until Adobe returns `lastPage: true`.
- Stop strict GET retrieval on failed requests, malformed JSON, unsuccessful API responses, or invalid page envelopes.
- Preserve warning and partial-output behavior for callers that do not select `-ErrorAction Stop`.
### 1.0.5 - 2024.12.13
- Added encrypted client secret support

### 1.0.4 - 2024.12.05
- Improve documentation

### 1.0.3 - 2024.12.05
- Added `Invoke-AdobeBulk` to allow bulk operations on Adobe users, as the API is very strict on rate limiting
- Added some documentation
- Improvements overall

### 1.0.2 - 2024.10.03
- Fixes `Get-AdobeUser` to return all users when no filter is provided

### 1.0.1 - 2024.10.03
- Small fix in verbose message

### 1.0.0
- Initial release