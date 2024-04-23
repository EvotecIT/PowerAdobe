Import-Module .\PowerAdobe.psd1 -Force

$connectAdobeSplat = @{
    ClientID     = '464'
    ClientSecret = 'p8e'
    Scopes       = 'openid, AdobeID, user_management_sdk'
    Organization = '783'
}

$Authorization = Connect-Adobe @connectAdobeSplat -Verbose
$Authorization | Format-Table

$Users = Get-AdobeUser
$Users | Format-Table