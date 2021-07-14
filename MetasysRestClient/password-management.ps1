
using namespace Microsoft.PowerShell.SecretManagement

$prefix = "imm"
$prefixLength = $prefix.Length + 1

Set-StrictMode -Version 3


function Get-SavedMetasysUsers {
    <#
    .SYNOPSIS
        Finds and returns user names associated with saved Metasys credentials.

    .DESCRIPTION
        The Invoke-MetasysMethod module includes functions that may update a secret vault.
        This cmdlet finds and returns the user names of Metasys accounts for a host that
        matches the provided 'SiteHost'. If no 'SiteHost' parameter argument is provided
        then all user names for all hosts will be returned.

        Note: This cmdlet only returns user names associated with Metasys credentials that
        have been added using this or other cmdlets of Invoke-MetasysMethod module.

    .OUTPUTS
        The list of matching user names.

    .EXAMPLE
        PS > Get-SavedMetasysUsers -SiteHost adx55

        Gets the list of users that have been saved for the site host adx55

    #>
    param (
        # The host name or ip address of the site host
        [string]$SiteHost
    )

    $searchFor = "${prefix}:$siteHost*"

    $secretInfo = Get-SecretInfo -Name $searchFor -ErrorAction SilentlyContinue

    if (!$secretInfo) {
        return
    }

    if ($SiteHost) {
        $UserName = @{label = "UserName"; expression = { $_.Name.Substring($prefixLength + $SiteHost.Length + 1) } }
        return $secretInfo | Select-Object $UserName
    }
    else {
        $userNameExpression = {
            $lastColon = $_.Name.LastIndexOf(":")
            if ($lastColon -lt 0) {
                return $null
            }
            return $_.Name.Substring($lastColon + 1)
        }
        $siteHostExpression = {

            $firstColon = $_.Name.IndexOf(":")
            $lastColon = $_.Name.LastIndexOf(":")

            if ($firstColon -eq $lastColon) {
                return $null
            }

            return $_.Name.Substring($firstColon + 1, $lastColon - $firstColon - 1)
        }

        $userNameSelector = @{label = "UserName"; expression = $userNameExpression }
        $hostSelector = @{label = "SiteHost"; expression = $siteHostExpression }

        $regex = [System.Text.RegularExpressions.Regex]::new("^${prefix}:[^:]+:[^:]+$")

        return $secretInfo | Where-Object { $regex.Match($_.Name).Success } |  Select-Object $hostSelector, $userNameSelector #| Where-Object { $null -ne $_.UserName } | Where-Object { $null -ne $_.SiteHost }


    }


}

function Get-SavedMetasysPassword {
    <#
    .SYNOPSIS
        Finds and returns the password associated with saved Metasys credentials.

    .DESCRIPTION
        The Invoke-MetasysMethod module includes functions that may update a secret vault.
        This cmdlet finds and returns the password of a Metasys account for a host that
        matches the provided 'SiteHost' and a user that matches 'UserName'. The password
        is returned as a SecureString object unless the '-AsPlainText' parameter switch
        is used, in which ase the password is returned in plain text.

    .OUTPUTS
        System.Object

    .EXAMPLE
        PS > Get-SavedMetasysPassword -SiteHost adx55 -UserName fred
        System.Security.SecureString

        Gets the password for fred on host adx55

    .EXAMPLE
        PS > Get-SavedMetasysPassword -SiteHost adx55 -UserName fred -AsPlainText
        PlainTextPassword

        Gets the password for fred on host adx55 and returns it as plain text

    #>
    param (
        # The host name or ip address of the site host to search for
        [Parameter(Mandatory=$true)]
        [string]$SiteHost,
        [Parameter(Mandatory=$true)]
        # The user name to search for
        [string]$UserName,
        # Return the password back as plain text
        [switch]$AsPlainText
    )

    $secretInfo = Get-SecretInfo -Name "${prefix}:${SiteHost}:$UserName" -ErrorAction SilentlyContinue

    if (!$secretInfo) {
        return
    }

    if ($secretInfo -is [System.Object[]]) {
        $secretInfo = $secretInfo[0]
    }

    $secret = Get-Secret -Name $secretInfo.Name -Vault $secretInfo.VaultName

    if ($AsPlainText.IsPresent) {
        return $secret | ConvertFrom-SecureString -AsPlainText
    }

    return $secret
}

function Remove-SavedMetasysPassword {
    <#
    .SYNOPSIS
        Finds and removes the password associated with saved Metasys credentials.

    .DESCRIPTION
        The Invoke-MetasysMethod module includes functions that may update a secret vault.
        This cmdlet finds and removes the Metasys credentials for a host that
        matches the provided 'SiteHost' and a user that matches 'UserName'.

    .EXAMPLE
        PS > Remove-SavedMetasysPassword -SiteHost adx55 -UserName fred

        Finds and removes the password for fred on adx55

    #>
    param(
        # The host name or ip address of the site host to search for
        [Parameter(Mandatory=$true)]
        [String]$SiteHost,
        # The user name to search for
        [Parameter(Mandatory=$true)]
        [String]$UserName
    )

    Get-SecretInfo -Name "${prefix}:${SiteHost}:$UserName" -ErrorAction SilentlyContinue | ForEach-Object { Remove-Secret -Name $_.Name }

}

function Set-SavedMetasysPassword {
    <#
    .SYNOPSIS
        Saves Metasys credentials

    .DESCRIPTION
        This cmdlet saves Metasys credentials into the default secret vault

    .EXAMPLE
        PS > Set-SavedMetasysPassword -SiteHost adx55 -UserName fred -Password $password

        Assuming $password is a SecureString that contains the password, this example
        saves fred's password for adx55.

    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SiteHost,
        [Parameter(Mandatory=$true)]
        [string]$UserName,
        [Parameter(Mandatory=$true)]
        [SecureString]$Password
    )

    Set-Secret -Name "${prefix}:${SiteHost}:$UserName" -SecureStringSecret $Password
}

Export-ModuleMember -Function "Get-SavedMetasysUsers", "Get-SavedMetasysPassword", "Remove-SavedMetasysPassword", "Set-SavedMetasysPassword"
