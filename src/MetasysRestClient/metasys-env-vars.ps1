Set-StrictMode -Version 3
class MetasysEnvVars {
    static [string] getSiteHost() {
        return $env:METASYS_HOST
    }

    static [void] setSiteHost([string]$siteHost) {
        $env:METASYS_HOST = $siteHost
    }

    static [string] getVersion() {
        return $env:METASYS_VERSION
    }

    static [void] setVersion([string]$version) {
        $env:METASYS_VERSION = $version
    }

    static [DateTimeOffset] getExpires() {
        $aDate = [DateTimeOffset]::Now
        if ([DateTimeOffset]::TryParse($env:METASYS_EXPIRES, [ref]$aDate)) {
            return $aDate
        }
        return $null
    }

    static [void] setExpires([DateTimeOffset]$expires) {
        $env:METASYS_EXPIRES = $expires.ToString("o")
    }

    static [SecureString] getToken() {
        if ($env:METASYS_ACCESS_TOKEN) {
            return ConvertTo-SecureString $env:METASYS_ACCESS_TOKEN
        }
        return $null
    }

    static [void] setToken([SecureString]$token) {
        $env:METASYS_ACCESS_TOKEN = ConvertFrom-SecureString -SecureString $token
    }

    static [String] getTokenAsPlainText() {
        $secureToken = [MetasysEnvVars]::getToken()
        if ($secureToken) {
            return (ConvertFrom-SecureString -SecureString $secureToken -AsPlainText)
        }

        return $null
    }

    static [void] setTokenAsPlainText([String]$token) {
        [MetasysEnvVars]::setToken(($token | ConvertTo-SecureString -AsPlainText))
    }

    static [string] getLast() {
        return $env:METASYS_LAST_RESPONSE
    }

    static [void] setLast([string]$last) {
        $env:METASYS_LAST_RESPONSE = $last
    }

    static [void] clear() {
        $env:METASYS_ACCESS_TOKEN = $null
        $env:METASYS_EXPIRES = $null
        $env:METASYS_HOST = $null
        $env:METASYS_LAST_HEADERS = $null
        $env:METASYS_LAST_RESPONSE = $null
        $env:METASYS_LAST_STATUS_CODE = $null
        $env:METASYS_LAST_STATUS_DESCRIPTION = $null
        $env:METASYS_SKIP_CERTIFICATE_CHECK = $null
        $env:METASYS_USER_NAME = $null
        $env:METASYS_VERSION = $null
    }

    static [void] setHeaders([Hashtable]$headers) {
        $env:METASYS_LAST_HEADERS = ConvertTo-Json -Depth 15 $headers
    }

    static [string] getHeaders() {
        return $env:METASYS_LAST_HEADERS
    }

    static [void] setStatus([int]$code, [string]$description) {
        $env:METASYS_LAST_STATUS_CODE = $code
        $env:METASYS_LAST_STATUS_DESCRIPTION = $description
    }

    static [string] getStatus() {
        return "$($env:METASYS_LAST_STATUS_CODE) ($($env:METASYS_LAST_STATUS_DESCRIPTION))"
    }

    static [Boolean] getSkipCertificateCheck() {
        # Need to convert string value into Boolean
        if ($env:METASYS_SKIP_CERTIFICATE_CHECK -eq "True") {
            return $true
        }
        else {
            return $false
        }
    }

    static [void] setSkipCertificateCheck([Boolean]$SkipCertificateCheck) {
        $env:METASYS_SKIP_CERTIFICATE_CHECK = $SkipCertificateCheck
    }

    static [string] getUserName() {
        return $env:METASYS_USER_NAME
    }

    static [void] setUserName([String]$UserName) {
        $env:METASYS_USER_NAME = $UserName
    }

}


function Set-MetasysAccessToken {
    <#
    .SYNOPSIS
        Stores the token as a secure string in current session.
    .DESCRIPTION
        Using this command takes the place of using `Connect-MetasysAccount` and as such
        it takes many of the same parameters like `MetasysHost` and `Version`.

        If you have a valid Metasys token from a previous login, you can use it in
        your current session by setting it with this command.

        It's mandatory that you also include the `MetasysHost`

        If you know the
        expiration time include that in the call. If you don't provide an expiration time
        then the session will assume no expiration; however eventually the token will
        fail to work and you'll get an error.
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AccessToken,
        [Parameter(Mandatory = $true)]
        [string]$MetasysHost,
        [DateTimeOffset]$Expires = [DateTimeOffset]::MaxValue,
        [switch]$SkipCertificateCheck,
        [string]$Version = "5"
    )

    [MetasysEnvVars]::setTokenAsPlainText($AccessToken)
    [MetasysEnvVars]::setExpires($Expires)
    [MetasysEnvVars]::setSiteHost($MetasysHost)
    [MetasysEnvVars]::setSkipCertificateCheck($SkipCertificateCheck)

    if ($Version -eq "") {
        $Version = (Get-MetasysDefaultApiVersion) ?? (Get-MetasysLatestVersion)
        Write-Information "No version specified. Defaulting to v$Version"
    }
    [MetasysEnvVars]::setVersion($Version)

}

Export-ModuleMember -Function Set-MetasysAccessToken
