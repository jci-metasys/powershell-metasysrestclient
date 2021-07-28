
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "The access token comes back in plain text, to convert to secure string I must use -AsPlainText", Scope = 'Function', Target = 'Connect-MetasysAccount')]
param()

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

    .Example
        $password = Read-Host -Prompt "password" -AsSecureString
        Connect-MetasysAccount -MetasysHost oas -UserName userName -Password $password

        After prompting for a password (stored as a secure string), connects the host named `oas` with
        the specified user name and password.
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

    Clear-MetasysEnvVariables | Out-Null

    if (!$MetasysHost) {
        Write-Information "No MetasysHost specified. Prompting for value."
        $MetasysHost = Read-Host -Prompt "Metasys Host"
    }

    if (!$UserName) {
        Write-Information "No UserName specified. Searching secret management."
        $users = Get-SavedMetasysUsers -SiteHost $MetasysHost

        if ($users -and $users.Count -eq 1) {
            Write-Information "A single matching user account found for $MetasysHost"
            $UserName = $users | Select-Object -ExpandProperty UserName
        }
        else {
            Write-Information "Multiple matching user accounts found for $MetasysHost. Prompting for value for UserName."
            $UserName = Read-Host -Prompt "UserName"
        }
    }

    if (!$Password) {
        Write-Information "No Password specified. Search secret management for user $UserName on $MetasysHost and if none found prompting for value."
        $Password = (Get-SavedMetasysPassword -SiteHost $MetasysHost -UserName $UserName) ?? (Read-Host -Prompt "Password" -AsSecureString)
    }

    if (!$Version) {
        Write-Information "No version specified. Defaulting to v$LatestVersion"
        $Version = $LatestVersion
    }

    $body = @{
        username = $UserName;
        password = ConvertFrom-SecureString -AsPlainText $Password
    } | ConvertTo-Json

    $uri = "https://$MetasysHost/api/v$Version/login"
    try {
        Write-Information "Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' -Body '{ `"username`": `"$UserName`", `"password`": `"********`" }' -SkipCertificateCheck:`$$SkipCertificateCheck"
        $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' -Body $body -SkipCertificateCheck:$SkipCertificateCheck
    }
    catch {
        Write-Error $_
        return
    }
    Write-Information "Login was successful. Saving environment variables."
    $env:METASYS_ACCESS_TOKEN = $response.accessToken | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
    $env:METASYS_EXPIRES = $response.expires
    $env:METASYS_HOST = $MetasysHost
    $env:METASYS_VERSION = $Version
}

Set-Alias -Name cma -Value Connect-MetasysAccount

Export-ModuleMember -Function Connect-MetasysAccount
Export-ModuleMember -Alias cma
