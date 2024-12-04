function Set-AdobeUser {
    <#
    .SYNOPSIS
    Update Adobe User information using Adobe API

    .DESCRIPTION
    Update Adobe User information using Adobe API. Applies only to Enterprise and Federated users
    Independent Adobe IDs are managed by the individual user and cannot be updated through the User Management API.
    Attempting to update information for a user who has an Adobe ID will result in an error.

    .PARAMETER EmailAddress
    Parameter description

    .PARAMETER NewEmailAddress
    Parameter description

    .PARAMETER Country
    Parameter description

    .PARAMETER FirstName
    Parameter description

    .PARAMETER LastName
    Parameter description

    .PARAMETER UserName
    Parameter description

    .PARAMETER BulkProcessing
    Switch to enable bulk processing mode.

    .EXAMPLE
    $SetInformaiton = Set-AdobeUser -EmailAddress 'przemek@test.pl' -NewEmailAddress 'przemek@test1.pl' -LastName 'Klys' -WhatIf -Verbose
    $SetInformaiton

    .NOTES
    General notes
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $EmailAddress,
        [string] $NewEmailAddress,
        [string] $Country,
        [string] $FirstName,
        [string] $LastName,
        [string] $UserName,
        [switch] $BulkProcessing
    )

    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Set-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    $UpdateObject = [ordered] @{
        "update" = [ordered] @{
            email     = $NewEmailAddress
            country   = $Country
            firstname = $FirstName
            lastname  = $LastName
            username  = $UserName
        }
    }

    Remove-EmptyValue -Hashtable $UpdateObject -Recursive -Rerun 2
    if (-not $UpdateObject) {
        Write-Warning -Message 'Set-AdobeUser - You need to provide at least one value to update'
        return
    }
    $Data = [ordered] @{
        user      = $EmailAddress
        requestID = "action_$(Get-Random)"
        do        = @(
            $UpdateObject
        )
    }

    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($EmailAddress, 'Update Adobe User')) { $false } else { $true }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}