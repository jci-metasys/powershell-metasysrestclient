using namespace System
using namespace System.IO

function Invoke-MetasysMethod {
    <#
    .SYNOPSIS
        Invokes methods of the Metasys REST API

    .DESCRIPTION
        This function allows you to invoke various methods of the Metasys REST API.
        Once a session is established (on the first invocation) the session state
        is maintained in the terminal session. This allows you to make additional
        calls with less boilerplate text for each call.

    .OUTPUTS
        The payloads from Metasys as Powershell objects.

    .EXAMPLE
        Invoke-MetasysMethod -Reference thesun:thesun

        This will prompt you for a hostname and your credentials and then attempt
        to look up the id of the object with the specified reference

    .EXAMPLE
        Invoke-MetasysMethod -Path /objects/$id

        After retrieving an id of an object (like in the previous example) and
        string it in variable $id, this example will read the default view of the
        object.

    .EXAMPLE
        Invoke-MetasysMethod -Path /alarms

        This will read the first page of alarms from the site.

    .EXAMPLE
        Invoke-MetasysMethod -Method Put -Path /objects/$id/commands/adjust -Body '[72.5]'

        This example will send the adjust command to the specified object (assuming
        a valid id is stored in $id).

    .LINK

        https://github.jci.com/cwelchmi/metasys-powershell-tutorial/blob/main/invoke-metasys-method.md

    #>

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
        # The relative path to an endpont. For example: /alarms
        # All of the relative paths are listed in the API Documentation
        # Path and Reference are mutally exclusive.
        [Parameter(Position=0)]
        [string]$Path,
        # Session information is stored in environment variables. To force a
        # cleanup use this switch to remove all environment variables. The next
        # time you invoke this function you'll need to provide a SiteHost
        [switch]$Clear,
        # The json payload to send with your request.
        [Parameter(ValueFromPipeline=$true)]
        [string]$Body,
        # The HTTP Method you are sending.
        [string]$Method = "Get",
        # The version of the API you intent to use
        [Int]$Version = 4,
        # Skips certificate validation checks. This includes all validations such as expiration, revocation, trusted root authority, etc.
        # [!WARNING] Using this parameter is not secure and is not recommended. This switch is only intended to be used against known hosts using a self-signed certificate for testing purposes. Use at your own risk.
        [switch]$SkipCertificateCheck,
        # A short cut for looking up the id of an object.
        [string]$Reference,
        # Rather than just returning the content, return the full web response
        # object will include extra like the response headers.
        [switch]$FullWebResponse,
        # A collection of headers to include in the request
        [hashtable]$Headers,
        # Erase credentials for the specified host
        [string]$DeleteCredentials
    )

    # Setup text background colors to match console background
    $backgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.PrivateData.DebugBackgroundColor = $backgroundColor
    $Host.PrivateData.ErrorBackgroundColor = $backgroundColor
    $Host.PrivateData.WarningBackgroundColor = $backgroundColor
    $Host.PrivateData.VerboseBackgroundColor = $backgroundColor

    Write-Output ""

    class MetasysEnvVars {
        static [string] getSiteHost() {
            return $env:METASYS_SITE_HOST
        }

        static [void] setSiteHost([string]$siteHost) {
            $env:METASYS_SITE_HOST = $siteHost
        }

        static [int] getVersion() {
            return $env:METASYS_VERSION
        }

        static [void] setVersion([int]$version) {
            $env:METASYS_VERSION = $version
        }

        static [string] getExpires() {
            return $env:METASYS_EXPIRES
        }

        static [void] setExpires([string]$expires) {
            $env:METASYS_EXPIRES = $expires
        }

        static [string] getToken() {
            return $env:METASYS_SECURE_TOKEN
        }

        static [void] setToken([string]$token) {
            $env:METASYS_SECURE_TOKEN = $token
        }

        static [string] getLast() {
            return $env:METASYS_LAST_RESPONSE
        }

        static [void] setLast([string]$last) {
            $env:METASYS_LAST_RESPONSE = $last
        }

        static [void] clear() {
            $env:METASYS_SECURE_TOKEN = $null
            $env:METASYS_SITE_HOST = $null
            $env:METASYS_VERSION = $null
            $env:METASYS_LAST_RESPONSE = $null
            $env:METASYS_EXPIRES = $null
            $env:METASYS_LAST_STATUS_CODE = $null
            $env:METASYS_LAST_STATUS_DESCRIPTION = $null
            $env:METASYS_LAST_HEADERS = $null
        }

        static [void] setHeaders($headers) {
            $env:METASYS_LAST_HEADERS = ConvertTo-Json -Depth 15 $headers
        }

        static [void] setStatus($code, $description) {
            $env:METASYS_LAST_STATUS_CODE = $code
            $env:METASYS_LAST_STATUS_DESCRIPTION = $description
        }

        static [Boolean] getDefaultSkipCheck() {
            return $env:METASYS_SKIP_CHECK_NOT_SECURE
        }

    }

    Set-StrictMode -Version 2

    # In Windows Powershell the $IsMacOS variable doesn't exist so calls to check
    # it's value fail. This function wraps the call.

    function isMacOS {
        if ($PSVersionTable.PSEdition -eq "Core") {
            return $IsMacOS
        }

        return $False
    }

    # The path can be
    # * relative to the https://hostname/api/v{next}
    # * absolute (eg https://hostname/api/v{next}/objects/{id}/attributes/presentValue)
    function buildUri {
        param (
            [string]$siteHost = [MetasysEnvVars]::getSiteHost(),
            [int]$version = [MetasysEnvVars]::getVersion(),
            [string]$baseUri = "api",
            [string]$path
        )

        $uri = [Uri]::new($path, [UriKind]::RelativeOrAbsolute)
        if ($uri.IsAbsoluteUri) {
            return $uri
        }

        $fullPath = "https://$siteHost/$([Path]::Join($baseUri, "v" + $version, $path))"
        return [Uri]::new($fullPath)
    }

    # The uri can be
    # * relative to the https://hostname/api/v{next}
    # * absolute (eg https://hostname/api/v{next}/objects/{id}/attributes/presentValue)
    function buildRequest {
        param (
            [string]$method = "Get",
            [string]$uri,
            [string]$body = $null,
            [string]$token = [MetasysEnvVars]::getToken(),
            [string]$version
        )

        $request = @{
            Method               = $method
            Uri                  = buildUri -path $Path -version $version
            Body                 = $body
            Authentication       = "bearer"
            Token                = ConvertTo-SecureString $token
            SkipCertificateCheck = $SkipCertificateCheck
            ContentType          = "application/json"
            Headers              = @{}
        }

        if ($Headers) {
            foreach ($header in $Headers.GetEnumerator()) {
                $request.Headers[$header.Key] = $header.Value
            }
        }

        return $request
    }

    function find-internet-user {
        param (
            [string]$siteHost
        )

        if (!(isMacOS)) {
            return
        }

        $cred = Invoke-Expression "security find-internet-password -s $siteHost 2>/dev/null"
        if ($cred) {
            $userNameLine = $cred | Where-Object { $_.StartsWith("    ""acct") }
            if ($userNameLine) {
                $userName = $userNameLine.Split('=')[1].Trim('"')
                return $userName
            }
        }
    }

    function find-internet-password {
        param (
            [string]$siteHost,
            [string]$userName
        )

        if (!(isMacOS)) {
            return
        }

        $passwordEntry = Invoke-Expression "security find-internet-password -s $siteHost -a $userName -w 2>/dev/null"
        if ($passwordEntry) {
            return ConvertTo-SecureString $passwordEntry -AsPlainText
        }
    }

    function clear-internet-password {
        param(
            [String]$siteHost
        )

        if (!$IsMacOS) {
            return
        }

        Invoke-Expression "security delete-internet-password -s $siteHost 1>/dev/null"
    }
    function add-internet-password {
        param(
            [string]$siteHost,
            [string]$userName,
            [SecureString]$password
        )

        if (!(isMacOS)) {
            return
        }

        $plainText = ConvertFrom-SecureString -SecureString $password -AsPlainText

        Invoke-Expression "security add-internet-password -U -s $siteHost -a $userName -w $plainText -c mgw1  "

    }

    If (($Version -lt 2) -or ($Version -gt 4)) {
        Write-Error -Message "Version out of range. Should be 2, 3 or 4"
        return
    }

    if ($Clear.IsPresent) {
        [MetasysEnvVars]::clear()
        return # end the program
    }

    if ($DeleteCredentials) {
        clear-internet-password $DeleteCredentials
        return # end the program
    }

    if (!$SkipCertificateCheck.IsPresent) {
        $SkipCertificateCheck =[MetasysEnvVars]::getDefaultSkipCheck()
    }

    # Login Region

    $ForceLogin = $false

    if ([MetasysEnvVars]::getExpires()) {
        $expiration = [Datetime]::Parse([MetasysEnvVars]::getExpires())
        if ([Datetime]::now -gt $expiration) {
            # Token is expired, require login
            $ForceLogin = $true
        }
        else {
            # attempt to renew the token to keep it fresh
            $refreshRequest = @{
                Method               = "Get"
                Uri                  = buildUri -path "/refreshToken"
                Authentication       = "bearer"
                Token                = ConvertTo-SecureString -String ([MetasysEnvVars]::getToken())
                SkipCertificateCheck = $SkipCertificateCheck
            }
            try {
                $refreshResponse = Invoke-RestMethod @refreshRequest
                [MetasysEnvVars]::setExpires($refreshResponse.expires)
                [MetasysEnvVars]::setToken( (ConvertFrom-SecureString -SecureString $refreshResponse.accessToken) )

            }
            catch {
                # refreshing doesn't seem to work
            }


        }
    }

    if (($Login) -or (![MetasysEnvVars]::getToken()) -or ($ForceLogin) -or ($SiteHost -and ($SiteHost -ne [MetasysEnvVars]::getSiteHost()))) {
        if (!$SiteHost) {
            $SiteHost = Read-Host -Prompt "Site host"
        }

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
            [MetasysEnvVars]::setToken((ConvertFrom-SecureString -SecureString $secureToken))
            [MetasysEnvVars]::setSiteHost($SiteHost)
            [MetasysEnvVars]::setExpires($loginResponse.expires)
            [MetasysEnvVars]::setVersion($Version)
        }
        catch {
            Write-Host "An error occurred:"
            Write-Host $_
            return
        }
    }

    if ($Path -and $Reference) {
        Write-Warning "-Path and -Reference are mutually exclusive"
        return
    }

    if (!$Path -and !$Reference) {
        return
    }

    if ($Reference) {
        $Path = "/objectIdentifiers?fqr=" + $Reference
        $request = buildRequest -uri (buildUri -path $Path) -version $Version
    }

    if ($Path) {
        $request = buildRequest -uri (buildUri -path $Path) -method $Method -body $Body -version $Version
    }

    $response = $null
    $responseObject = $null
    try {
        $responseObject = Invoke-WebRequest @request -SkipHttpErrorCheck
        if ($FullWebResponse.IsPresent) {
            $response = $responseObject
        }
        elseif ($responseObject.StatusCode -ge 400) {
            $body = [String]::new($responseObject.Content)
            Write-Error -Message ("Status: " + $responseObject.StatusCode.ToString() + " (" + $responseObject.StatusDescription + ")")
            $responseObject.Headers.Keys | ForEach-Object {$_ + ": " + $responseObject.Headers[$_] | Write-Output}
            Write-Output $body
        }
        else {
            if ($responseObject) {
                if (($responseObject.Headers["Content-Length"] -eq "0") -or ($responseObject.Headers["Content-Type"] -like "*json*")) {
                    $response = [String]::new($responseObject.Content)
                } else {
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
    Write-Output $(ConvertTo-SecureString -String $env:METASYS_SECURE_TOKEN | ConvertFrom-SecureString -AsPlainText)
}

function Show-LastMetasysHeaders {

    $headers = ConvertFrom-Json $env:METASYS_LAST_HEADERS
    foreach ($header in $headers.PSObject.Properties) {
        Write-Output "$($header.Name): $($header.Value -join ',')"
    }
}

function Show-LastMetasysStatus {
    Write-Output "$($env:METASYS_LAST_STATUS_CODE) ($($env:METASYS_LAST_STATUS_DESCRIPTION))"
}

function ConvertFrom-JsonSafely {
    param(
        [String]$json
    )

    try {
        return ConvertFrom-Json $json
    } catch {
        return ConvertFrom-Json -AsHashtable $json
    }
}

function Show-LastMetasysResponseBody {
    param (
        [string]$body = $env:METASYS_LAST_RESPONSE
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
    return ConvertFrom-JsonSafely $env:METASYS_LAST_RESPONSE
}



Export-ModuleMember -Function 'Invoke-MetasysMethod', 'Show-LastMetasysHeaders', 'Show-LastMetasysAccessToken', 'Show-LastMetasysResponseBody', 'Show-LastMetasysFullResponse', 'Get-LastMetasysResponseBodyAsObject', 'Show-LastMetasysStatus'
