# Invoke-RestMethod -Method POST -Uri "https://thesun.cg.na.jci.com/api/v3/login" -Body @{ username="michael"; password="BlahBlah2!" } -ContentType "applicaton/json" -SkipCertificateCheck
param(
    [string]$Site,
    [string]$UserName,
    [Boolean]$Login = $false,
    [string]$Path,
    [switch]$Clear,
    [string]$Body,
    [string]$Method = "Get",
    [Int]$Version = 3,
    [switch]$SkipCertificateCheck
)

class MetasysEnvVars
{
    static [string] getSite() {
        return $env:METASYS_SITE
    }

    static [void] setSite([string]$site) {
        $env:METASYS_SITE = $site
    }

    static [int] getVersion() {
        return $env:METASYS_VERSION
    }

    static [void] setVersion([int]$version) {
        $enf:METASYS_VERSION = $version
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
        $env:METASYS_SITE = $null
        $env:METASYS_VERSION = $null
        $env:METASYS_LAST_RESPONSE = $null
        $env:METASYS_EXPIRES = $null
    }

}

Set-StrictMode -Version 2

function buildUri {
    param (
        [string]$site = [MetasysEnvVars]::getSite(),
        [int]$version = [MetasysEnvVars]::getVersion(),
        [string]$baseUri = "api",
        [string]$path
    )

    $uri = [System.Uri] ("https://" + $site + "/" + ([System.IO.Path]::Join($baseUri, "v" + $version, $path)))
    return $uri
}

If (($Version -lt 2) -or ($Version -gt 3)) {
    Write-Error -Message "Version out of range. Should be 2 or 3"
    return
}

if ($Clear.IsPresent) {
    [MetasysEnvVars]::clear()
    return # end the program
}

# Login Region

$ForceLogin = false

if ([MetasysEnvVars]::getExpires()) {
    $expiration = [Datetime]::Parse([MetasysEnvVars]::getExpires())
    if ([Datetime]::now -gt $expiration) {
        # Token is expired, require login
        $ForceLogin = $true
    } else {
        # attempt to renew the token to keep it fresh
        $refreshRequest = @{
            Method = "Get"
            Uri = buildUri -path "/refreshToken"
            Authentication = "bearer"
            Token = ConvertTo-SecureString -String ([MetasysEnvVars]::getToken())
            SkipCertificateCheck = true
        }
        try {
            $refreshResponse = Invoke-RestMethod @refreshRequest
            [MetasysEnvVars]::setExpires($refreshResponse.expires)
            [MetasysEnvVars]::setToken( (ConvertFrom-SecureString -SecureString $refreshResponse.accessToken) )

        } catch {
            # refreshing doesn't seem to work
        }


    }
}

if (($Login) -or (![MetasysEnvVars]::getToken()) -or ($ForceLogin)) {
    if (!$Site) {
        $Site = Read-Host -Prompt "Site"
    }
    if (!$UserName) {
        $UserName = Read-Host -Prompt "UserName"
    }
    $password = Read-Host -Prompt "Password" -AsSecureString

    $jsonObject = @{
        username = "Michael"
        password = ConvertFrom-SecureString -SecureString $password -AsPlainText
    }
    $json = (ConvertTo-Json $jsonObject)

    $loginRequest = @{
        Method               = "Post"
        Uri                  = buildUri -site $Site -version $Version -path "login" #[System.Uri] ("https://" + $Site + "/api/v" + $Version + "/login")
        Body                 = $json
        ContentType          = "application/json"
        SkipCertificateCheck = true
    }

    try {
        $loginResponse = Invoke-RestMethod @loginRequest
        $loginSuccessful = $true
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }

    if ($loginSuccessful) {
        $secureToken = ConvertTo-SecureString -String $loginResponse.accessToken -AsPlainText
        [MetasysEnvVars]::setToken((ConvertFrom-SecureString -SecureString $secureToken))
        $env:METASYS_SITE = $Site
        [MetasysEnvVars]::setExpires($loginResponse.expires)
        $env:METASYS_VERSION = $Version
    }
}


if ($Path) {

    $request = @{
        Method               = $Method
        Uri                  = buildUri -path $Path
        Authentication       = "bearer"
        Token                = ConvertTo-SecureString ([MetasysEnvVars]::getToken())
        SkipCertificateCheck = true
    }
    $response = Invoke-RestMethod @request
    [MetasysEnvVars]::setLast((ConvertTo-Json $response -Depth 15))
    return $response
}

