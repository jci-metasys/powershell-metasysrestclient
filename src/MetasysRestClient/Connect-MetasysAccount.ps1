Set-StrictMode -Version 3
Set-Variable -Name LatestVersion -Value 4 -Option Constant
function Connect-MetasysAccount {
    <#
    .Synopsis
    Connect to Metasys with an authenticated account for use with functions in MetasysRestClient module

    .DESCRIPTION
    The `Connect-MetasysAccount` function connects to a Metasys site with an authenticated account for use with
    functions from the MetasysRestClient PowerShell module.

    .Example
        Connect-MetasysAccount

        Prompts for `MetasysHost`, `UserName` and `Password` and attempts to authenticate with the host using
        the username and password as credentials.
    #>
    [CmdLetBinding(PositionalBinding = $false)]
    param(

        # A hostname or ip address. This is the device `Connect-MetasysAccount` will athenticated with.
        #
        # Aliases: -h, -host, -SiteHost
        [Alias("h", "host", "SiteHost")]
        [String]$MetasysHost,

        # The username of an account on the host
        #
        # Alias: -u
        [Alias("u")]
        [String]$UserName,

        # The password of an account on the host. Note: `Password` takes a `SecureString`
        #
        # Alias: -p
        [Alias("p")]
        [SecureString]$Password,

        # The API version to use on the host.
        #
        # Alias: -v
        [Alias("v")]
        [ValidateRange(2, 4)]
        [Int32]$Version = 4,

        # Skips certificate validation checks. This includes all validations
        # such as expiration, revocation, trusted root authority, etc.
        # [!WARNING] Using this parameter is not secure and is not recommended.
        # This switch is only intended to be used against known hosts using a
        # self-signed certificate for testing purposes. Use at your own risk.
        [Switch]$SkipCertificateCheck
    )

    Clear-MetasysEnvVariables

    if (!$MetasysHost) {
        $MetasysHost = Read-Host -Prompt "Metasys Host"
    }

    if (!$UserName) {
        $users = Get-SavedMetasysUsers -SiteHost $MetasysHost

        if ($users -and $users.Count -eq 1) {
            $UserName = $users | Select-Object -ExpandProperty UserName
        }
        else {
            $UserName = Read-Host -Prompt "UserName"
        }
    }

    if (!$Password) {

        $Password = (Get-SavedMetasysPassword -SiteHost $MetasysHost -UserName $UserName) ?? (Read-Host -Prompt "Password" -AsSecureString)
    }

    if (!$Version) {
        $Version = $LatestVersion
    }

    $body = @{
        username = $UserName;
        password = ConvertFrom-SecureString -AsPlainText $Password
    } |  ConvertTo-Json

    $uri = "https://$MetasysHost/api/v$Version/login"
    $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' -Body $body -SkipCertificateCheck:$SkipCertificateCheck
    $env:METASYS_ACCESS_TOKEN = $response.accessToken | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
    $env:METASYS_EXPIRES = $response.expires
    $env:METASYS_HOST = $MetasysHost
    $env:METASYS_VERSION = $Version
}

Set-Alias -Name cmsa -Value Connect-MetasysAccount

Export-ModuleMember -Function Connect-MetasysAccount
Export-ModuleMember -Alias cmsa
