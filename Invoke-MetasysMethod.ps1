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

If (($Version -lt 2) -or ($Version -gt 3)) {
    Write-Error -Message "Version out of range. Should be 2 or 3"
    return
}

if ($Clear.IsPresent) {
    $env:METASYS_SECURE_TOKEN = $null
    $env:METASYS_SITE = $null
    $env:METASYS_VERSION = $null
    $env:METASYS_LAST_RESPONSE = $null
    $env:METASYS_EXPIRES = $null
    return
}

# Login Region

if ($env:METASYS_EXPIRES) {
    $expiration = [Datetime]::Parse($env:METASYS_EXPIRES)
    if ([Datetime]::now -gt $expiration) {
        # Token is expired, require login
        $Login = $true
    } else {
        # attempt to renew the token to keep it fresh
        $refreshRequest = @{
            Method = "Get"
            Uri = [System.Uri]("https://" + $env:METASYS_SITE +  "/api/v" + $env:METASYS_VERSION + "/refreshToken")
            Authentication = "bearer"
            Token = ConvertTo-SecureString -String $env:METASYS_SECURE_TOKEN
            SkipCertificateCheck = true
        }
        try {
            $refreshResponse = Invoke-RestMethod @refreshRequest
            $env:METASYS_EXPIRES = $refreshResponse.expires
            $env:METASYS_SECURE_TOKEN = ConvertFrom-SecureString -SecureString $refreshResponse.accessToken

        } catch {
            # refreshing doesn't seem to work
        }


    }
}

if (($Login -eq $true) -or (!$env:METASYS_SECURE_TOKEN)) {
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
        Uri                  = [System.Uri] ("https://" + $Site + "/api/v" + $Version + "/login")
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
        $env:METASYS_SECURE_TOKEN = ConvertFrom-SecureString -SecureString $secureToken
        $env:METASYS_SITE = $Site
        $env:METASYS_EXPIRES = $loginResponse.expires
        $env:METASYS_VERSION = $Version
    }
}


if ($Path) {

    $request = @{
        Method               = $Method
        Uri                  = [System.Uri]("https://" + $env:METASYS_SITE + "/api/v3" + $Path)
        Authentication       = "bearer"
        Token                = ConvertTo-SecureString $env:METASYS_SECURE_TOKEN
        SkipCertificateCheck = true
    }
    $response = Invoke-RestMethod @request
    $env:METASYS_LAST_RESPONSE = ConvertTo-Json $response -Depth 15
    return $response
}

