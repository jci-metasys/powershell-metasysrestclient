
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

    The alias for this command is `cma`. Some of the examples in this help use `cma` instead of `Connect-MetasysAccount`.

    DYNAMIC PARAMETERS

    Connect-MetasysAccount offers a very useful dynamic parameter. The Alias parameter features tab completion so that you can easily select the host you want to connect to. The list of choices is dyanmically read from your configuration file. (See NOTES)

    -Alias <System.String>

    An alias from your configuration file. See NOTES for more information on configuring an alias.  If you specify an Alias and a MetasysHost the host specified by Alias is used.

    NOTE: This is the only positional parameter so you can invoke this command as simply as this:

    > cma myhost

    assuming myhost is a configured alias.

    .PARAMETER Alias
    An alias from your configuration file. See NOTES for more information on configuration files.

    .Example
    Connect-MetasysAccount

    Prompts for `MetasysHost`, `UserName` and `Password` and attempts to authenticate with the host using the username and password as credentials.

    .Example
    $password = Read-Host -Prompt "password" -AsSecureString
    Connect-MetasysAccount -MetasysHost oas -UserName userName -Password $password

    After prompting for a password (stored as a secure string), connects the host named `oas` with the specified user name and password.

    .Example
    cma host1

    Assuming you have this alias in your configuration file (see NOTES), this will prompt you for your password and connect you with the configured username and version.

    .NOTES
    The Metasys REST API mandates that you specify the version of the API you wish to call. This command assumes that you wish to use the latest version of the API (v5 at time of writing). If you wish to use an older version of the API use the -Version parameter. To avoid having to specify this every time you connect you have two choices. You can use a configuration file as described below to specify a different version for each host you connect to. Or you can modify your start up profile to set the environment variable $env:METASYS_DEFAULT_API_VERSION to which ever version you wish. (For example you could set it to 4).

    Whichever version of the API was used to connect to Metasys will be used for every other call in your session (unless you override that with the -Version parameter or by specifying a full URL).

    Connecting to a site can be greatly simplified with the use of a configuration file named .metasysrestclient in your home directory. The file should be JSON and should look something like this

    {
        "hosts": [
            {
                "alias": "host1",
                "hostname": "host1.company.com"
            },
            {
                "alias": "myhost",
                "hostname": "myhost.company.com",
                "username": "john",
                "version": "4",
                "skip-certificate-check": true
            }
        ]
    }

    In a valid configuration file each host entry must have an alias and a hostname. The other properties are optional but typically very useful.

    With this configuration file in place I can connect to myhost.company.com, with user "john", and using version 4 with this command:

    cma myhost

    TAB COMPLETION

    With a configuration file in place you can use tab completion to pick the host you want. If you don't recall all of your aliases, just type `cma <TAB KEY>` and they will all be listed.

    Any parameters given on the command line (-UserName, -Version, -SkipCertificateCheck) will override any values in the configuration file. This allows you to still use an alias to avoid typing a full hostname, but let you override the version (for example).

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
    DynamicParam {

        # Set the dynamic parameters' name
        $ParameterName = 'Alias'

        # Create the dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.Position = 0

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet, but only if aliases are found
        $arrSet = ReadAliases
        if ($arrSet) {
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)
        }

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        # Bind the parameter to a friendly variable
        $Alias = $PSBoundParameters[$ParameterName]
    }

    process {
        Clear-MetasysEnvVariables | Out-Null

        # Use the config file (if present) to lookup the actual host name
        # and user name (if supplied)
        $HostEntry = Read-ConfigFile -Alias $Alias
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
}

Set-Alias -Name cma -Value Connect-MetasysAccount

Export-ModuleMember -Function Connect-MetasysAccount
Export-ModuleMember -Alias cma
