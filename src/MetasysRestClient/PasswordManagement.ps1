
using namespace Microsoft.PowerShell.SecretManagement

Set-StrictMode -Version 3

$prefix = "imm"
$prefixLength = $prefix.Length + 1


function aSecretVaultIsAvailable {
    [OutputType([Boolean])]
    param()

    $vaultAvailable = $false
    try {
        # if this works we know we have a registered vault
        $secretVault = Get-SecretVault

        # let's see if we can import the module for the vault
        $module = Import-Module -Name $secretVault.ModuleName -EA SilentlyContinue -PassThru

        if ($module) {
            $vaultAvailable = $true
        }

    }
    catch {
    }

    if (!$vaultAvailable) {
        Write-Information "There are currently no secret vaults available."
    }
    $vaultAvailable
}


function Get-SavedMetasysUsers {
    <#
    .SYNOPSIS
        Finds and returns user names associated with saved Metasys credentials.

    .DESCRIPTION
        The Invoke-MetasysMethod module includes functions that may update a secret vault. This cmdlet finds and returns the user names of Metasys accounts for a host that matches the provided 'MetasysHost'. If no 'MetasysHost' parameter argument is provided then all user names for all hosts will be returned.

        Note: This cmdlet only returns user names associated with Metasys credentials that have been added using this or other cmdlets of Invoke-MetasysMethod module.

    .OUTPUTS
        The list of matching user names.

    .EXAMPLE
        PS > Get-SavedMetasysUsers -MetasysHost adx55

        Gets the list of users that have been saved for the site host adx55

    #>
    param (
        # A hostname or ip address.
        #
        # Aliases: -h, -host, -SiteHost
        [Alias("h", "host", "SiteHost")]
        [string]$MetasysHost
    )

    if (!(aSecretVaultIsAvailable)) {
        return
    }

    $searchFor = ($MetasysHost) ? "$prefix`:$metasysHost`:*" : "$prefix`:*"

    $secretInfo = Get-SecretInfo -Name $searchFor -ErrorAction SilentlyContinue

    if (!$secretInfo) {
        return
    }

    if ($MetasysHost) {
        $UserName = @{label = "UserName"; expression = { ($_.Name -split ":")[2] } }
        $HostName = @{label = "Host"; expression = { ($_.Name -split ":")[1] } }
        if ($secretInfo -is [Object[]]) {
            return $secretInfo | Select-Object $HostName, $UserName | Where-Object { $_.Host -eq $MetasysHost } | Select-Object UserName
        }
        else {
            return $secretInfo | Select-Object $UserName
        }
    }
    else {
        $userNameExpression = {
            $lastColon = $_.Name.LastIndexOf(":")
            if ($lastColon -lt 0) {
                return $null
            }
            return $_.Name.Substring($lastColon + 1)
        }
        $metasysHostExpression = {

            $firstColon = $_.Name.IndexOf(":")
            $lastColon = $_.Name.LastIndexOf(":")

            if ($firstColon -eq $lastColon) {
                return $null
            }

            return $_.Name.Substring($firstColon + 1, $lastColon - $firstColon - 1)
        }

        $userNameSelector = @{label = "UserName"; expression = $userNameExpression }
        $hostSelector = @{label = "Host"; expression = $metasysHostExpression }

        $regex = [System.Text.RegularExpressions.Regex]::new("^${prefix}:[^:]+:[^:]+$")

        return $secretInfo | Where-Object { $regex.Match($_.Name).Success } |  Select-Object $hostSelector, $userNameSelector #| Where-Object { $null -ne $_.UserName } | Where-Object { $null -ne $_.MetasysHost }


    }


}

function Get-SavedMetasysPassword {
    <#
    .SYNOPSIS
        Finds and returns the password associated with saved Metasys credentials.

    .DESCRIPTION
        The Invoke-MetasysMethod module includes functions that may update a secret vault. This cmdlet finds and returns the password of a Metasys account for a host that matches the provided 'MetasysHost' and a user that matches 'UserName'.

        The password is returned as a SecureString object unless the '-AsPlainText' parameter switch is used, in which case the password is returned in plain text.

    .OUTPUTS
        System.Object

    .EXAMPLE
        PS > Get-SavedMetasysPassword -MetasysHost adx55 -UserName fred
        System.Security.SecureString

        Gets the password for fred on host adx55

    .EXAMPLE
        PS > Get-SavedMetasysPassword -MetasysHost adx55 -UserName fred -AsPlainText
        PlainTextPassword

        Gets the password for fred on host adx55 and returns it as plain text

    #>
    param (
        # A hostname or ip address.
        #
        # Aliases: -h, -host, -SiteHost
        [Alias("h", "host", "SiteHost")]
        [Parameter(Mandatory = $true)]
        [string]$MetasysHost,

        # The username of an account on the host
        #
        # Alias: -u
        [Alias("u")]
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        # Return the password back as plain text
        [switch]$AsPlainText
    )

    if (!(aSecretVaultIsAvailable)) {
        return
    }

    $secretInfo = Get-SecretInfo -Name "${prefix}:${MetasysHost}:$UserName" -ErrorAction SilentlyContinue

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
        Finds and removes the password associated with saved Metasys
        credentials.

    .DESCRIPTION
        The Invoke-MetasysMethod module includes functions that may update a secret vault. This cmdlet finds and removes the Metasys credentials for a host that matches the provided 'MetasysHost' and a user that matches 'UserName'.

    .EXAMPLE
        PS > Remove-SavedMetasysPassword -MetasysHost adx55 -UserName fred

        Finds and removes the password for fred on adx55

    #>
    param(
        # A hostname or ip address.
        #
        # Aliases: -h, -host, -SiteHost
        [Alias("h", "host", "SiteHost")]
        [Parameter(Mandatory = $true)]
        [string]$MetasysHost,

        # The username of an account on the host
        #
        # Alias: -u
        [Alias("u")]
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    if (!(aSecretVaultIsAvailable)) {
        return
    }

    Get-SecretInfo -Name "${prefix}:${MetasysHost}:$UserName" -ErrorAction SilentlyContinue | ForEach-Object { Remove-Secret -Name $_.Name }

}

function Set-SavedMetasysPassword {
    <#
    .SYNOPSIS
        Saves Metasys credentials

    .DESCRIPTION
        This cmdlet saves Metasys credentials into the default secret vault

    .EXAMPLE
        PS > Set-SavedMetasysPassword -MetasysHost adx55 -UserName fred -Password $password

        Assuming $password is a SecureString that contains the password, this example saves fred's password for adx55.

    #>
    param(
        # A hostname or ip address.
        #
        # Aliases: -h, -host, -SiteHost
        [Alias("h", "host", "SiteHost")]
        [Parameter(Mandatory = $true)]
        [string]$MetasysHost,

        # The username of an account on the host
        #
        # Alias: -u
        [Alias("u")]
        [Parameter(Mandatory = $true)]
        [string]$UserName,

        # The password of an account on the host. Note: `Password` takes a
        # `SecureString`
        #
        # Alias: -p
        [Alias("p")]
        [Parameter(Mandatory = $true)]
        [SecureString]$Password
    )
    if (!(aSecretVaultIsAvailable)) {
        return
    }

    Set-Secret -Name "${prefix}:${MetasysHost}:$UserName" -SecureStringSecret $Password
}

Export-ModuleMember -Function "Get-SavedMetasysUsers", "Get-SavedMetasysPassword", "Remove-SavedMetasysPassword", "Set-SavedMetasysPassword"
