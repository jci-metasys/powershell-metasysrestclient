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

    static [SecureString] getToken() {
        if ($env:METASYS_SECURE_TOKEN) {
            return ConvertTo-SecureString $env:METASYS_SECURE_TOKEN
        }
        return $null
    }

    static [String] getTokenAsPlainText() {
        $secureToken = [MetasysEnvVars]::getToken()
        if ($secureToken) {
            return (ConvertFrom-SecureString -SecureString $secureToken -AsPlainText)
        }

        return $null
    }

    static [void] setToken([SecureString]$token) {
        $env:METASYS_SECURE_TOKEN = ConvertFrom-SecureString -SecureString $token
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
        $env:METASYS_USER_NAME = $null
    }

    static [void] setHeaders([Hashtable]$headers) {
        $env:METASYS_LAST_HEADERS = ConvertTo-Json -Depth 15 $headers
    }

    static [void] setStatus([int]$code, [string]$description) {
        $env:METASYS_LAST_STATUS_CODE = $code
        $env:METASYS_LAST_STATUS_DESCRIPTION = $description
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
