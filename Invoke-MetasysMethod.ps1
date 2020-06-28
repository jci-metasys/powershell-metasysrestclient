# Invoke-RestMethod -Method POST -Uri "https://thesun.cg.na.jci.com/api/v3/login" -Body @{ username="michael"; password="BlahBlah2!" } -ContentType "applicaton/json" -SkipCertificateCheck
param(
    [string]$Site,
    [string]$UserName,
    [Boolean]$Login = $false,
    [string]$Path,
    [Boolean]$Clear = $false,
    [string]$Body,
    [string]$Method = "Get",
    [Int]$Version = 3
)

If (($Version -lt 2) -or ($Version -gt 3)) {
    Write-Error -Message "Version out of range. Should be 2 or 3"
    return
}

if ($Clear) {
    $env:METASYS_SECURE_TOKEN = $null
    $env:METASYS_SITE = $null
    return
}

# Login Region

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
        Method = "Post"
        Uri = [System.Uri] "https://thesun.cg.na.jci.com/api/v3/login"
        Body = $json
        ContentType = "application/json"
        SkipCertificateCheck = true
    }

    try {
        $loginResponse = Invoke-RestMethod @loginRequest
        $loginSuccessful = $true
    } catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }

    if ($loginSuccessful) {
        $secureToken = ConvertTo-SecureString -String $loginResponse.accessToken -AsPlainText
        $env:METASYS_SECURE_TOKEN = ConvertFrom-SecureString -SecureString $secureToken
        $env:METASYS_SITE = $Site
    }
}


if ($Path) {

    $uriBuilder = New-Object -TypeName System.UriBuilder -ArgumentList  "https",  $METASYS_SITE
    $uriBuilder.Path = "api/v" + $Version + "/" + $Path
    $uri = $uriBuilder.Uri

    $request = @{
        Method = $Method
        Uri = [System.Uri]("https://thesun.cg.na.jci.com/api/v3" + $Path)
        Authentication = "bearer"
        Token = ConvertTo-SecureString $env:METASYS_SECURE_TOKEN
        SkipCertificateCheck = true
    }
    $response = Invoke-RestMethod @request
    $env:METASYS_LAST_RESPONSE = ConvertTo-Json $response -Depth 15
    return $response
}

