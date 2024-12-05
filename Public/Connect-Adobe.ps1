function Connect-Adobe {
    <#
    .SYNOPSIS
    Connects to the Adobe API.

    .DESCRIPTION
    The Connect-Adobe cmdlet establishes a connection to the Adobe API using the provided credentials and scopes. It handles token retrieval and caching for subsequent API calls.

    .PARAMETER ClientID
    The Client ID for Adobe API authentication.

    .PARAMETER ClientSecret
    The Client Secret for Adobe API authentication.

    .PARAMETER Scopes
    The scopes for API access.

    .PARAMETER Organization
    The Adobe organization identifier.

    .PARAMETER ExistingToken
    Use an existing token if available.

    .PARAMETER DoNotSuppress
    Suppress suppression of the token information.

    .PARAMETER Force
    Force a new token retrieval even if a valid token exists.

    .EXAMPLE
    Connect-Adobe -ClientID "your_client_id" -ClientSecret "your_client_secret" -Scopes "openid, AdobeID" -Organization "your_org_id"
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory)][string] $ClientID,
        [parameter(Mandatory)][string] $ClientSecret,
        [parameter(Mandatory)][string] $Scopes,
        [parameter(Mandatory)][string] $Organization,
        [switch] $ExistingToken,
        [switch] $DoNotSuppress,
        [switch] $Force
    )
    # Check for curent token
    $CurrentTime = (Get-Date).AddSeconds(2)

    if ($Script:AdobeTokenInformation.Expires -lt $CurrentTime -or $Force) {
        if ($ExistingToken) {
            Write-Verbose -Message "Connect-Adobe - Using existing token within command"
            $Url = $Script:AdobeTokenInformation.Url
            $Headers = $Script:AdobeTokenInformation.Headers
            $Body = $Script:AdobeTokenInformation.Body
        } else {
            $Headers = [ordered] @{
                'Content-Type' = 'application/x-www-form-urlencoded'
            }
            $Body = [ordered] @{
                'client_id'     = $ClientID
                'client_secret' = $ClientSecret
                'grant_type'    = 'client_credentials'
                'scope'         = $Scopes
            }
            $Url = 'https://ims-na1.adobelogin.com/ims/token/v3'

            $Script:AdobeTokenInformation = [ordered] @{
                Organization = $Organization
                Url          = $Url
                Headers      = $Headers
                Token        = $null
                Expires      = $null
                Body         = $Body
            }
        }

        try {
            $Response = Invoke-RestMethod -Method Post -Uri $Url -Headers $Headers -Body $Body -ErrorAction Stop -Verbose:$false
        } catch {
            Write-Warning -Message "Connect-Adobe - Unable to connect to organization '$Organization' with user '$UserName'. Error $($_.Exception.Message)"
            return
        }

        $Script:AdobeTokenInformation.Token = $Response.access_token
        $Script:AdobeTokenInformation.Expires = [DateTime]::Now + ([TimeSpan]::FromSeconds($Response.expires_in))
        $Script:AdobeTokenInformation.Headers = @{
            #'Content-Type'  = 'application/x-www-form-urlencoded'
            'Authorization' = "Bearer $($Script:AdobeTokenInformation.Token)"
            "X-Api-Key"     = "$ClientID"
            'Content-type'  = 'application/json'
        }
        if ($DoNotSuppress) {
            $Script:AdobeTokenInformation
        }
    } else {
        $WhenExpires = $Script:AdobeTokenInformation.expires - $CurrentTime
        Write-Verbose -Message "Connect-Adobe - Using existing cached token (Expires in: $WhenExpires)"
        if ($DoNotSuppress -and -not $ExistingToken) {
            $Script:AdobeTokenInformation
        }
    }
}