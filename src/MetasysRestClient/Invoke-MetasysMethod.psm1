using namespace System
using namespace System.IO
using namespace System.Security
using namespace Microsoft.PowerShell.Commands
using namespace System.Management.Automation

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

function createErrorStringFromResponseObject {
    param(
        [WebResponseObject]$responseObject
    )

    $body = [String]::new($responseObject.Content)
    $errorMessage = "`nStatus: " + $responseObject.StatusCode.ToString() + " (" + $responseObject.StatusDescription + ")"
    $responseObject.Headers.Keys | ForEach-Object { $errorMessage += "`n" + $_ + ": " + $responseObject.Headers[$_] }
    $errorMessage += "`n$body"
    return $errorMessage
}

function invokeWithWarningsOff {
    <#
        .SYNOPOSIS
            Invokes a script block with warning preference set to SilentlyContinue
            This is used in this file to invoke the password management functions that
            write warnings when called directly by a client. But for which we'd rather
            not see warnings if they are called by Invoke-MetasysMethod.

            It seems that I should just be able to invoke my password management functions with
            -WarningAction SilentlyContinue but that doesn't seem to work. This is my work around
            for now.
    #>
    param (
        [ScriptBlock]$script
    )
    $oldWarningPref = $WarningPreference
    $WarningPreference = "SilentlyContinue"
    try {
        & $script
    }
    finally {
        $WarningPreference = $oldWarningPref
    }
}


function Invoke-MetasysMethod {
    <#
    .SYNOPSIS
        Sends an HTTPS request to a Metasys device running Metasys REST API

    .DESCRIPTION
        This function allows you to call methods of the Metasys REST API.
        Once a session is established (on the first invocation) the session state
        is maintained in the terminal session. This allows you to make additional
        calls with less boilerplate text necessary for each call.

    .OUTPUTS
        System.String
            The payloads from Metasys are formatted JSON strings. This is the
            default return type for this function.

        PSObject, Hashtable
            If the switch `ReturnBodyAsObject` is set then this function attempts
            to convert the response to a custom object. In some cases, the JSON string
            may contain properties that only differ in casing and can't be converted
            to a PSObject. In such cases, a Hashtable is returned instead.

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

        https://github.com/metasys-server/powershell-metasysrestapi

    #>

    [CmdletBinding(PositionalBinding = $false)]
    param(
        # The relative or absolute url for an endpont. For example: /alarms
        # All of the urls are listed in the API Documentation
        [Alias("p")]
        [Parameter(Position = 0)]
        [string]$Path,
        # The payload to send with your request.
        [Parameter(ValueFromPipeline = $true)]
        [Alias("b")]
        [string]$Body,
        # The HTTP Method you are sending.
        [Alias("verb", "m")]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = "Get",
        # The version of the API you intend to use
        [Alias("v")]
        [ValidateRange(2, 4)]
        [Int]$Version,
        # Skips certificate validation checks. This includes all validations
        # such as expiration, revocation, trusted root authority, etc.
        # [!WARNING] Using this parameter is not secure and is not recommended.
        # This switch is only intended to be used against known hosts using a
        # self-signed certificate for testing purposes. Use at your own risk.
        [switch]$SkipCertificateCheck,
        # A collection of headers to include in the request
        [Alias("hd")]
        [hashtable]$Headers,
        # TODO: Add support for password to be passed in
        [SecureString]$Password,
        # Return the response as PSObject or Hashtable instead of JSON string
        [Alias("o", "object")]
        [Switch]$ReturnBodyAsObject
    )

    BEGIN {
        Set-Variable -Name fiveMinutes -Value ([TimeSpan]::FromMinutes(5)) -Option Constant

        setBackgroundColorsToMatchConsole


        assertPowershellCore

        if (!$Path) {
            Write-Information "Path not supplied. Please enter a path"
            $Path = Read-Host -Prompt "Path"
        }

        if (!$SkipCertificateCheck.IsPresent) {
            $SkipCertificateCheck = [MetasysEnvVars]::getDefaultSkipCheck()
        }

        $uri = [Uri]::new($path, [UriKind]::RelativeOrAbsolute)
        if ($uri.IsAbsoluteUri) {
            $versionSegment = $uri.Segments[2]
            $versionNumber = $versionSegment.SubString(1, $versionSegment.Length - 2)
            if ($Version -gt 0 -and $versionNumber -ne $Version) {
                Write-Error "An absolute url was given for Path and it specifies a version ('$versionNumber') that conflicts with Version ('$Version')"
                continue
            }
        }

        If ($Version -eq 0) {
            # Default to the latest version
            # TODO: Also check a environment variable or even a config file for reasonable defaults.
            $Version = 4
        }

        # Login Region

        if ($null -eq ([MetasysEnvVars]::getToken()) ) {
            Write-Error "No connection to a Metasys site exists. Please connect using Connect-MetasysAccount"
            continue
        }
        else {
            if ([MetasysEnvVars]::getExpires()) {
                $expiration = [MetasysEnvVars]::getExpires()
                if ([DateTimeOffset]::UtcNow -gt $expiration) {
                    # Token is expired, attempt to connect with previously used site host and user name
                    try {
                        Connect-MetasysAccount -SiteHost ([MetasysEnvVars]::getSiteHost()) -UserName ([MetasysEnvVars]::getUserName()) -Version ([MetasysEnvVars]::getVersion()) `
                            -SkipCertificateCheck:$SkipCertificateCheck
                    }
                    catch {
                        Write-Error "Session expired and attempt to re-connect failed"
                        continue
                    }
                }
                elseif ([DateTimeOffset]::UtcNow -gt ($expiration - $fiveMinutes)) {

                    # attempt to renew the token as it will expire soon
                    $uri = buildUri -siteHost ([MetasysEnvVars]::getSiteHost()) -version ([MetasysEnvVars]::getVersion()) -path "/refreshToken"
                    $refreshRequest = buildRequest -uri $uri`
                        -token ([MetasysEnvVars]::getToken()) -skipCertificateCheck:$SkipCertificateCheck

                    try {
                        Write-Information -Message "Attempting to refresh access token"
                        $refreshResponse = Invoke-RestMethod @refreshRequest
                        [MetasysEnvVars]::setExpires($refreshResponse.expires)
                        [MetasysEnvVars]::setTokenAsPlainText($refreshResponse.accessToken)
                        Write-Information -Message "Refresh token successful"
                    }
                    catch {
                        Write-Debug "Error attempting to refresh token"
                        Write-Debug $_
                        continue
                    }
                }
            }
        }
        $uri = buildUri -path $Path -version $Version -siteHost ([MetasysEnvVars]::getSiteHost())

    }

    # PROCESS block is needed if you accept input from pipeline like Body in this function
    PROCESS {

        $request = buildRequest -uri $uri -method $Method -body $Body -token ([MetasysEnvVars]::getToken()) -skipCertificateCheck:$SkipCertificateCheck `
            -headers $Headers


        $response = $null
        $responseObject = $null

        Write-Information -Message "Attempting request"

        try {
            $responseObject = Invoke-WebRequest @request
        }
        catch {
            # Catches errors like host name can't be found and also 4xx, 5xx http errors
            Write-Error $_
            return
        }

        if ($responseObject) {
            if (($responseObject.Headers["Content-Length"] -eq "0") -or ($responseObject.Headers["Content-Type"] -like "*json*") -or ($responseObject.StatusCode -eq 204)) {
                $response = [System.Text.Encoding]::UTF8.GetString($responseObject.Content)
            }
            else {
                Write-Error "An unexpected content type was found"
                Write-Error (createErrorStringFromResponseObject -responseObject $responseObject)
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
        elseif ($null -ne $response) {
            Show-LastMetasysResponseBody
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
    $body = [MetasysEnvVars]::getLast()
    if ($body) {
        ConvertFrom-JsonSafely $body | ConvertTo-Json -Depth 20
    }
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

Set-Alias -Name imm -Value Invoke-MetasysMethod

Export-ModuleMember -Function 'Invoke-MetasysMethod', 'Show-LastMetasysHeaders', 'Show-LastMetasysAccessToken', 'Show-LastMetasysResponseBody', 'Show-LastMetasysFullResponse', `
    'Get-LastMetasysResponseBodyAsObject', 'Show-LastMetasysStatus', 'Get-LastMetasysHeadersAsObject', 'Clear-MetasysEnvVariables'

Export-ModuleMember -Alias 'imm'

