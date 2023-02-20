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
        $env:METASYS_HOST = $null
        $env:METASYS_VERSION = $null
        $env:METASYS_LAST_RESPONSE = $null
        $env:METASYS_EXPIRES = $null
        $env:METASYS_LAST_STATUS_CODE = $null
        $env:METASYS_LAST_STATUS_DESCRIPTION = $null
        $env:METASYS_LAST_HEADERS = $null
        $env:METASYS_USER_NAME = $null
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

    static [Boolean] getDefaultSkipCheck() {
        return $env:METASYS_SKIP_CHECK_NOT_SECURE
    }

    static [string] getUserName() {
        return $env:METASYS_USER_NAME
    }

    static [void] setUserName([String]$UserName) {
        $env:METASYS_USER_NAME = $UserName
    }

}
