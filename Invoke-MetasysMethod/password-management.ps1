
using namespace Microsoft.PowerShell.SecretManagement

$prefix = "imm"
$prefixLength = $prefix.Length + 1

Set-StrictMode -Version 3


function Get-MetasysUsers {
    param (
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

function Get-MetasysPassword {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SiteHost,
        [Parameter(Mandatory=$true)]
        [string]$UserName
    )

    $secretInfo = Get-SecretInfo -Name "${prefix}:${SiteHost}:$UserName" -ErrorAction SilentlyContinue

    if (!$secretInfo) {
        return
    }

    if ($secretInfo -is [System.Object[]]) {
        $secretInfo = $secretInfo[0]
    }

    $secret = Get-Secret -Name $secretInfo.Name -Vault $secretInfo.VaultName

    return $secret
}

function Remove-MetasysPassword {
    param(
        [Parameter(Mandatory=$true)]
        [String]$SiteHost,
        [Parameter(Mandatory=$true)]
        [String]$UserName
    )

    Get-SecretInfo -Name "${prefix}:${SiteHost}:$UserName" -ErrorAction SilentlyContinue | ForEach-Object { Remove-Secret -Name $_.Name }

}

function Set-MetasysPassword {
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

Export-ModuleMember -Function "Get-MetasysUsers", "Get-MetasysPassword", "Remove-MetasysPassword", "Set-MetasysPassword"
