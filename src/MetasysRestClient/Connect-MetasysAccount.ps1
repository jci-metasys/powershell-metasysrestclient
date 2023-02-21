
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "The access token comes back in plain text, to convert to secure string I must use -AsPlainText", Scope = 'Function', Target = 'Connect-MetasysAccount')]
param()

Set-StrictMode -Version 3
Set-Variable -Name LatestVersion -Value 5 -Option Constant

function Connect-MetasysAccount {
    <#
    .Synopsis
    Connect to Metasys with an authenticated account for use with functions in MetasysRestClient module

    .DESCRIPTION
    The `Connect-MetasysAccount` function connects to a Metasys site with an authenticated account for use with functions from the MetasysRestClient PowerShell module.

    .Example
    Connect-MetasysAccount

    Prompts for `MetasysHost`, `UserName` and `Password` and attempts to authenticate with the host using the username and password as credentials.

    .Example
    $password = Read-Host -Prompt "password" -AsSecureString
    Connect-MetasysAccount -MetasysHost oas -UserName userName -Password $password

    After prompting for a password (stored as a secure string), connects the host named `oas` with the specified user name and password.

    .NOTES
    The Metasys REST API mandates that you specify the version of the API you wish to call. This command assumes that you wish to use the latest version of the API (v5 at time of writing). If you wish to use an older version of the API use the -Version parameter. To avoid having to specify this every time you connect you can modify your start up profile to set the environment variable $env:METASYS_DEFAULT_API_VERSION to which ever version you wish. (For example you could set it to 4).

    Whichever version of the API was used to connect to Metasys will be used for every other call in your session (unless you override that with the -Version parameter or by specifying a full URL).
    #>
    [CmdLetBinding(PositionalBinding = $true)]
    param(

        # A hostname or ip address. This is the device `Connect-MetasysAccount` will athenticated with.
        #
        # Aliases: -h, -host, -SiteHost
        [Alias("h", "host", "SiteHost")]
        [Parameter(Position=0)]
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
        # Acceptable values: 2, 3, 4, 5
        # Alias: -v
        [Alias("v")]
        [string]$Version,

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

    # Use the config file (if present) to lookup the actual host name
    # and user name (if supplied)
    $HostEntry = Read-ConfigFile -Alias $MetasysHost
    if ($HostEntry) {
        $HostEntryProperties = $HostEntry.PSObject.Properties
        $MetasysHost = $HostEntry.hostname
        Write-Information "Alias '$($HostEntry.alias)' found in '.metasysrestclient'. Using '$MetasysHost' as new value for -MetaysHost"
        if (!$UserName -and $HostEntryProperties['username']) {
            $UserName = $HostEntry.username
            Write-Information "Alias '$($HostEntry.alias)' has an associated username. Using '$UserName' as value for -UserName"
        }
        if (!$Version -and $HostEntryProperties['version']) {
            $Version = $HostEntry.version
            Write-Information "Alias '$($HostEntry.alias)' has an associated version. Using '$Version' as value for -Version"
        }
        if ($HostEntryProperties['skip-certificate-check']) {
            $SkipCertificateCheck = $true
            Write-Information "Alias s'$($HostEntry.alias)' is configured to skip certificate checking."
        }
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

    if ($Version -eq "") {
        $Version = $env:METASYS_DEFAULT_API_VERSION ?? $LatestVersion
        Write-Information "No version specified. Defaulting to v$Version"
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
    [MetasysEnvVars]::setExpires($response.expires)
    [MetasysEnvVars]::setTokenAsPlainText($response.accessToken)
    [MetasysEnvVars]::setSiteHost($MetasysHost)
    [MetasysEnvVars]::setVersion($Version)
    [MetasysEnvVars]::setSkipCertificateCheck($SkipCertificateCheck)

    Write-Information "Saving credentials to vault"
    Set-SavedMetasysPassword -SiteHost $MetasysHost -UserName $UserName -Password $Password
}

Set-Alias -Name cma -Value Connect-MetasysAccount

Export-ModuleMember -Function Connect-MetasysAccount
Export-ModuleMember -Alias cma
