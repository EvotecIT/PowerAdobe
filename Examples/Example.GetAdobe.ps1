﻿Import-Module .\PowerAdobe.psd1 -Force

$connectAdobeSplat = @{
    ClientID     = '464'
    ClientSecret = 'p8e'
    Scopes       = 'openid, AdobeID, user_management_sdk'
    Organization = '783'
}

Connect-Adobe @connectAdobeSplat -Verbose

# Keep in mind of thresholds which are very strict for all users
$Users = Get-AdobeUser
$Users | Format-Table

$User = Get-AdobeUser -Email '<email>' -Verbose
$User | Format-Table

# Keep in mind of thresholds which are very strict for all groups
$Groups = Get-AdobeGroup -Verbose
$Groups | Format-Table

$GroupMembers = Get-AdobeGroupMember -GroupName 'Admins' -Verbose
$GroupMembers | Format-Table

$NewGroup = New-AdobeGroup -Name 'TestGroup2' -Description 'Test Group Description'
$NewGroup | Format-Table

$UpdateGroup = Set-AdobeGroup -Name 'TestGroup2' -NewName 'TestGroup3' -Description 'Test Group Description 3' -Verbose
$UpdateGroup | Format-Table