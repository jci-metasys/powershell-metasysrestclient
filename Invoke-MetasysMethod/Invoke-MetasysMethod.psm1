using namespace System
using namespace System.IO
using namespace System.Security
using namespace Microsoft.PowerShell.Commands

function assertPowershellCore {
    if ($PSVersionTable.PSEdition -ne "Core") {
        Write-Error "Windows Powershell is not supported. Please install PowerShell Core"
        Write-Error "See https://github.com/powershell/powershell"
        exit
    }
}

function assertValidVersion {
    param(
        [Int]$Version
    )
    If (($Version -lt 2) -or ($Version -gt 4)) {
        If ($Version -ne 0) {
            Write-Error -Message "Version out of range. Should be 2, 3 or 4" -Category InvalidArgument
            exit
        }
    }
}

function handleClearSwitch {
    param (
        [Switch]$Clear
    )

    if ($Clear.IsPresent) {
        [MetasysEnvVars]::clear()
        Write-Output "Environment variables cleared"
        exit # end the program
    }
}

function handleDeleteCredentialsFor {
    param (
        [string]$DeleteCredentialsFor
    )
    if ($DeleteCredentialsFor) {
        clear-internet-password $DeleteCredentialsFor
        exit
    }
}

function setBackgroundColorsToMatchConsole {
    # Setup text background colors to match console background
    $backgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.PrivateData.DebugBackgroundColor = $backgroundColor
    $Host.PrivateData.ErrorBackgroundColor = $backgroundColor
    $Host.PrivateData.WarningBackgroundColor = $backgroundColor
    $Host.PrivateData.VerboseBackgroundColor = $backgroundColor

    Write-Output ""
}

function Invoke-MetasysMethod {
    <#
    .SYNOPSIS
        Invokes methods of the Metasys REST API

    .DESCRIPTION
        This function allows you to invoke various methods of the Metasys REST API.
        Once a session is established (on the first invocation) the session state
        is maintained in the terminal session. This allows you to make additional
        calls with less boilerplate text necessary for each call.

    .OUTPUTS
        The payloads from Metasys as formatted JSON strings.

    .EXAMPLE
        Invoke-MetasysMethod /objects/$id

        Reads the default view of the specified object assuming $id contains a
        valid object identifier

    .EXAMPLE
        Invoke-MetasysMethod /alarms

        This will read the first page of alarms from the site.

    .EXAMPLE
        Invoke-MetasysMethod -Method Put /objects/$id/commands/adjust -Body '[72.5]'

        This example will send the adjust command to the specified object (assuming
        a valid id is stored in $id).

    .LINK

        https://github.jci.com/cwelchmi/metasys-powershell-tutorial/blob/main/invoke-metasys-method.md

    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'DeleteCredentialsFor', Justification = "This parameter doesn't actually contain a secret", Scope = 'Function')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        # The hostname or ip address of the site you wish to interact with
        [string]$SiteHost,
        # The username of the account you wish to use on this Site
        [string]$UserName,
        # A switch used to force Login. This isn't normally needed except
        # when you wish to switch accounts or switch sites. By using this
        # switch you will be prompted for the site or your credentials if
        # not supplied on the command line.
        [switch]$Login,
        # The relative or absolute url for an endpont. For example: /alarms
        # All of the urls are listed in the API Documentation
        [Parameter(Position = 0)]
        [string]$Path,
        # Session information is stored in environment variables. To force a
        # cleanup use this switch to remove all environment variables. The next
        # time you invoke this function you'll need to provide a SiteHost
        [switch]$Clear,
        # The payload to send with your request.
        [Parameter(ValueFromPipeline = $true)]
        [string]$Body,
        # The HTTP Method you are sending.
        [WebRequestMethod]$Method = "Get",
        # The version of the API you intent to use
        [Int]$Version,
        # Skips certificate validation checks. This includes all validations
        # such as expiration, revocation, trusted root authority, etc.
        # [!WARNING] Using this parameter is not secure and is not recommended.
        # This switch is only intended to be used against known hosts using a
        # self-signed certificate for testing purposes. Use at your own risk.
        [switch]$SkipCertificateCheck,
        # A collection of headers to include in the request
        [hashtable]$Headers,
        # Erase credentials for the specified host
        [string]$DeleteCredentialsFor,
        # TODO: Add support for password to be passed in
        [SecureString]$Password
    )

    setBackgroundColorsToMatchConsole

    Set-StrictMode -Version 2

    assertPowershellCore

    assertValidVersion $Version

    handleClearSwitch -Clear:$Clear

    handleDeleteCredentialsFor $DeleteCredentialsFor


    if (!$SkipCertificateCheck.IsPresent) {
        $SkipCertificateCheck = [MetasysEnvVars]::getDefaultSkipCheck()
    }

    $uri = [Uri]::new($path, [UriKind]::RelativeOrAbsolute)
    if ($uri.IsAbsoluteUri) {
        $versionSegment = $uri.Segments[2]
        $versionNumber = $versionSegment.SubString(1, $versionSegment.Length - 2)
        if ($Version -gt 0 -and $versionNumber -ne $Version) {
            Write-Error "An absolute url was given for Path and it specifies a version ('$versionNumber') that conflicts with Version ('$Version')"
            return
        }
    }

    If ($Version -eq 0) {
        # Default to the latest version
        # TODO: Also check a environment variable or even a config file for reasonable defaults.
        $Version = 4
    }

    # Login Region

    $ForceLogin = $false

    if ([MetasysEnvVars]::getExpires()) {
        $expiration = [Datetime]::Parse([MetasysEnvVars]::getExpires())
        if ([Datetime]::UtcNow -gt $expiration) {
            # Token is expired, require login
            $ForceLogin = $true
        }
        else {
            # attempt to renew the token to keep it fresh
            $refreshRequest = @{
                Method               = "Get"
                Uri                  = buildUri -path "/refreshToken"
                Authentication       = "bearer"
                Token                = [MetasysEnvVars]::getToken()
                SkipCertificateCheck = $SkipCertificateCheck
            }
            try {
                $refreshResponse = Invoke-RestMethod @refreshRequest
                [MetasysEnvVars]::setExpires($refreshResponse.expires)
                [MetasysEnvVars]::setToken((ConvertTo-SecureString $refreshResponse.accessToken -AsPlainText))

            }
            catch {
                Write-Debug "Error attemplting to refresh token"
                Write-Debug $_
            }


        }
    }

    # TODO: Also force login if $UserName -ne saved user name
    # TODO: Could also support multiple sessions by storing multiple access tokens keyed on username
    # TODO: When token expires but we have the credentials cached we could try to login again
    if (($Login) -or (![MetasysEnvVars]::getToken()) -or ($ForceLogin) -or ($SiteHost -and ($SiteHost -ne [MetasysEnvVars]::getSiteHost()))) {

        $SiteHost = $SiteHost ? $SiteHost : [MetasysEnvVars]::getSiteHost()
        if (!$SiteHost) {
            $SiteHost = Read-Host -Prompt "Site host"
        }

        $UserName = $UserName ? $UserName : [MetasysEnvVars]::getUserName()
        if (!$UserName) {
            # attempt to find a user name in keychain
            $UserName = find-internet-user($SiteHost)

            if (!$UserName) {
                $UserName = Read-Host -Prompt "UserName"
            }
        }

        $password = find-internet-password $SiteHost $UserName

        if (!$password) {
            $password = Read-Host -Prompt "Password" -AsSecureString

            ## Attempt to store credentials
            # TODO: Should only do this if successful
            add-internet-password $SiteHost  $UserName  $password
        }

        $jsonObject = @{
            username = $UserName
            password = ConvertFrom-SecureString -SecureString $password -AsPlainText
        }
        $json = (ConvertTo-Json $jsonObject)

        $loginRequest = @{
            Method               = "Post"
            Uri                  = buildUri -siteHost $SiteHost -version $Version -path "login"
            Body                 = $json
            ContentType          = "application/json"
            SkipCertificateCheck = $SkipCertificateCheck
        }

        try {
            $loginResponse = Invoke-RestMethod @loginRequest
            $secureToken = ConvertTo-SecureString -String $loginResponse.accessToken -AsPlainText
            [MetasysEnvVars]::setToken($secureToken)
            [MetasysEnvVars]::setSiteHost($SiteHost)
            [MetasysEnvVars]::setExpires($loginResponse.expires)
            [MetasysEnvVars]::setVersion($Version)
            [MetasysEnvVars]::setUserName($UserName)
        }
        catch {
            Write-Host "An error occurred:"
            Write-Host $_
            return
        }
    }

    if (!$Path) {
        return
    }



    $request = buildRequest -uri (buildUri -path $Path) -method $Method -body $Body -version $Version -token ([MetasysEnvVars]::getToken())

    $response = $null
    $responseObject = $null
    try {
        $responseObject = Invoke-WebRequest @request -SkipHttpErrorCheck
        if ($responseObject.StatusCode -ge 400) {
            $body = [String]::new($responseObject.Content)
            Write-Error -Message ("Status: " + $responseObject.StatusCode.ToString() + " (" + $responseObject.StatusDescription + ")")
            $responseObject.Headers.Keys | ForEach-Object { $_ + ": " + $responseObject.Headers[$_] | Write-Output }
            Write-Output $body
        }
        else {
            if ($responseObject) {
                if (($responseObject.Headers["Content-Length"] -eq "0") -or ($responseObject.Headers["Content-Type"] -like "*json*")) {
                    $response = [String]::new($responseObject.Content)
                }
                else {
                    Write-Output "An unexpected content type was found:"
                    Write-Output $([String]::new($responseObject.Content))
                }
            }
        }
    }
    catch {
        Write-Output "An unhandled error condition occurred:"
        Write-Error $_
    }
    # Only overwrite the last response if $response is not null
    if ($null -ne $response) {
        [MetasysEnvVars]::setLast($response)
        [MetasysEnvVars]::setHeaders($responseObject.Headers)
        [MetasysEnvVars]::setStatus($responseObject.StatusCode, $responseObject.StatusDescription)
    }

    return Show-LastMetasysResponseBody $response

}

function Show-LastMetasysAccessToken {
    Write-Output $(ConvertTo-SecureString -String ([MetasysEnvVars]::getToken()) | ConvertFrom-SecureString -AsPlainText)
}

function Show-LastMetasysHeaders {

    $headers = ConvertFrom-Json ([MetasysEnvVars]::getHeaders())
    foreach ($header in $headers.PSObject.Properties) {
        Write-Output "$($header.Name): $($header.Value -join ',')"
    }
}

function Show-LastMetasysStatus {
    Write-Output ([MetasysEnvVars]::getStatus())
}

function ConvertFrom-JsonSafely {
    param(
        [String]$json
    )

    try {
        return ConvertFrom-Json $json
    }
    catch {
        return ConvertFrom-Json -AsHashtable $json
    }
}

function Show-LastMetasysResponseBody {
    param (
        [string]$body = ([MetasysEnvVars]::getLast())
    )

    if ($null -eq $body -or $body -eq "") {
        Write-Output ""
        return
    }
    ConvertFrom-JsonSafely $body | ConvertTo-Json -Depth 20 | Write-Output
}

function Show-LastMetasysFullResponse {
    Show-LastMetasysStatus
    Show-LastMetasysHeaders
    Show-LastMetasysResponseBody
}

function Get-LastMetasysResponseBodyAsObject {
    return ConvertFrom-JsonSafely ([MetasysEnvVars]::getLast())
}



Export-ModuleMember -Function 'Invoke-MetasysMethod', 'Show-LastMetasysHeaders', 'Show-LastMetasysAccessToken', 'Show-LastMetasysResponseBody', 'Show-LastMetasysFullResponse', 'Get-LastMetasysResponseBodyAsObject', 'Show-LastMetasysStatus'

