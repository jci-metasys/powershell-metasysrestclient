using namespace System
using namespace System.IO
using namespace System.Security
using namespace Microsoft.PowerShell.Commands

Set-StrictMode -Version 3

# HACK: https://stackoverflow.com/a/49859001
# Otherwise on Linux I get "Unable to find type [WebRequestMethod]" error
Start-Sleep -Milliseconds 1

function assertPowershellCore {
    if ($PSVersionTable.PSEdition -ne "Core") {

        $errorString = "Windows Powershell is not supported. Please install PowerShell Core" + "`n" + "Windows Powershell is not supported. Please install PowerShell Core"
        throw $errorString
    }
}

function setBackgroundColorsToMatchConsole {
    # Setup text background colors to match console background
    $backgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.PrivateData.DebugBackgroundColor = $backgroundColor
    $Host.PrivateData.ErrorBackgroundColor = $backgroundColor
    $Host.PrivateData.WarningBackgroundColor = $backgroundColor
    $Host.PrivateData.VerboseBackgroundColor = $backgroundColor

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
        Invoke-MetasysMethod -Method Put /objects/$id/commands/adjust -Body '{ "parameters": [72.5] }'

        This example will send the adjust command to the specified object (assuming
        a valid id is stored in $id, and v4 of the API).

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
        # The payload to send with your request.
        [Parameter(ValueFromPipeline = $true)]
        [string]$Body,
        # The HTTP Method you are sending.
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = "Get",
        # The version of the API you intent to use
        [ValidateRange(2,4)]
        [Int]$Version,
        # Skips certificate validation checks. This includes all validations
        # such as expiration, revocation, trusted root authority, etc.
        # [!WARNING] Using this parameter is not secure and is not recommended.
        # This switch is only intended to be used against known hosts using a
        # self-signed certificate for testing purposes. Use at your own risk.
        [switch]$SkipCertificateCheck,
        # A collection of headers to include in the request
        [hashtable]$Headers,
        # TODO: Add support for password to be passed in
        [SecureString]$Password,
        [Switch]$ReturnBodyAsObject
    )

    PROCESS {


        setBackgroundColorsToMatchConsole


        assertPowershellCore

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
                $refreshRequest = buildRequest -method "Get" -uri (buildUri -path "/refreshToken" -version $Version) `
                    -token ([MetasysEnvVars]::getToken()) -skipCertificateCheck:$SkipCertificateCheck

                try {
                    Write-Verbose -Message "Attempting to refresh access token"
                    $refreshResponse = Invoke-RestMethod @refreshRequest
                    [MetasysEnvVars]::setExpires($refreshResponse.expires)
                    [MetasysEnvVars]::setToken((ConvertTo-SecureString $refreshResponse.accessToken -AsPlainText))
                    Write-Verbose -Message "Refresh token successful"
                }
                catch {
                    Write-Debug "Error attempting to refresh token"
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
                # attempt to find a user name in secret store
                $users = Get-MetasysUsers -SiteHost $SiteHost

                if ($users -is [System.Object[]]) {
                    Write-Information "Multiple UserNames found for this host. Please enter one below."
                    $users | ForEach-Object { Write-Information "$($_.UserName)" }

                }
                elseif ($null -ne $Users) {
                    $UserName = $users.UserName
                }

                if (!$UserName) {
                    $UserName = Read-Host -Prompt "UserName"
                }
            }

            if (!$Password) {
                Write-Verbose -Message "Attempting to get password for $SiteHost $UserName"
                $password = Get-MetasysPassword -SiteHost $SiteHost -UserName $UserName

                if (!$password) {
                    $password = Read-Host -Prompt "Password" -AsSecureString
                }
            }

            $jsonObject = @{
                username = $UserName
                password = ConvertFrom-SecureString -SecureString $password -AsPlainText
            }
            $json = (ConvertTo-Json $jsonObject)

            $loginRequest = buildRequest -method "Post" -uri (buildUri -siteHost $SiteHost -version $Version -path "login") `
                -body $json -skipCertificateCheck:$SkipCertificateCheck

            $loginResponse = Invoke-RestMethod @loginRequest
            $secureToken = ConvertTo-SecureString -String $loginResponse.accessToken -AsPlainText
            [MetasysEnvVars]::setToken($secureToken)
            [MetasysEnvVars]::setSiteHost($SiteHost)
            [MetasysEnvVars]::setExpires($loginResponse.expires)
            [MetasysEnvVars]::setVersion($Version)
            [MetasysEnvVars]::setUserName($UserName)
            Set-MetasysPassword -SiteHost $SiteHost -UserName $UserName -Password $Password
            Write-Verbose -Message "Login successful"
        }

        if (!$Path) {
            return
        }

        $request = buildRequest -uri (buildUri -path $Path -version $Version) -method $Method -body $Body -version  `
            $Version -token ([MetasysEnvVars]::getToken()) -skipCertificateCheck:$SkipCertificateCheck `
            -headers $Headers


        $response = $null
        $responseObject = $null

        Write-Verbose -Message "Attempting request"
        $responseObject = Invoke-WebRequest @request -SkipHttpErrorCheck
        if ($responseObject.StatusCode -ge 400) {
            Write-Error "The status code indicates an error"
            Write-Error (createErrorStringFromResponseObject -responseObject $responseObject)
        }
        else {
            if ($responseObject) {
                if (($responseObject.Headers["Content-Length"] -eq "0") -or ($responseObject.Headers["Content-Type"] -like "*json*") -or ($responseObject.StatusCode -eq 204)) {
                    $response = [String]::new($responseObject.Content)
                }
                else {
                    Write-Error "An unexpected content type was found"
                    Write-Error (createErrorStringFromResponseObject -responseObject $responseObject)
                }
            }
        }


        # Only overwrite the last response if $response is not null
        if ($null -ne $response) {
            [MetasysEnvVars]::setLast($response)
            [MetasysEnvVars]::setHeaders($responseObject.Headers)
            [MetasysEnvVars]::setStatus($responseObject.StatusCode, $responseObject.StatusDescription)
        }

        if ($ReturnBodyAsObject.IsPresent -and $null -ne $response) {
            Get-LastMetasysResponseBodyAsObject
        }
        else {
            Show-LastMetasysResponseBody $response
        }
    }

}

function Show-LastMetasysAccessToken {
    ConvertFrom-SecureString -AsPlainText -SecureString ([MetasysEnvVars]::getToken())
}

function Show-LastMetasysHeaders {

    $response = @()
    $headers = ConvertFrom-Json ([MetasysEnvVars]::getHeaders())
    foreach ($header in $headers.PSObject.Properties) {
        $response += "$($header.Name): $($header.Value -join ',')"
    }
    $response
}

function Show-LastMetasysStatus {
    ([MetasysEnvVars]::getStatus())
}

function ConvertFrom-JsonSafely {
    param(
        [String]$json
    )

    try {
        ConvertFrom-Json -InputObject $json
    }
    catch {
        ConvertFrom-Json -AsHashtable -InputObject $json
    }
}

function Show-LastMetasysResponseBody {
    param (
        [string]$body = ([MetasysEnvVars]::getLast())
    )

    if ($null -eq $body -or $body -eq "") {
        return
    }
    ConvertFrom-JsonSafely $body | ConvertTo-Json -Depth 20
}

function Show-LastMetasysFullResponse {
    (Show-LastMetasysStatus), (Show-LastMetasysHeaders), (Show-LastMetasysResponseBody) | Join-String -Separator `n
}

function Get-LastMetasysResponseBodyAsObject {
    ConvertFrom-JsonSafely ([MetasysEnvVars]::getLast())
}

function Get-LastMetasysHeadersAsObject {
    ConvertFrom-Json ([MetasysEnvVars]::getHeaders())
}

function Clear-MetasysEnvVariables {
    [MetasysEnvVars]::clear()
    "The environment variables related to the current Metasys sessions have been cleared."
}

Export-ModuleMember -Function 'Invoke-MetasysMethod', 'Show-LastMetasysHeaders', 'Show-LastMetasysAccessToken', 'Show-LastMetasysResponseBody', 'Show-LastMetasysFullResponse', `
    'Get-LastMetasysResponseBodyAsObject', 'Show-LastMetasysStatus', 'Get-LastMetasysHeadersAsObject', 'Clear-MetasysEnvVariables'

