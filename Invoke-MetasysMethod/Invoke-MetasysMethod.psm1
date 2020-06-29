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

        This will prompt you for the Site and your credentials and then attempt
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
    param(
        # The hostname or ip address of the site you wish to interact with
        [string]$Site,
        # The username of the account you wish to use on this Site
        [string]$UserName,
        # A switch used to force Login. This isn't normally needed except
        # when you wish to switch accounts or switch sites. By using this
        # switch you will be prompted for the site or your credentials if
        # not supplied on the command line.
        [switch]$Login,
        # The relative path to an endpont. For example: /alarms
        # All of the relative paths are listed in the API Documentation
        [string]$Path,
        # Session information is stored in environment variables. To force a
        # cleanup use this switch to remove all environment variables. The next
        # time you invoke this function you'll need to provide credentials and
        # a Site. Path and Reference are mutally exclusive.
        [switch]$Clear,
        # The json payload to send with your request.
        [string]$Body,
        # The HTTP Method you are sending.
        [string]$Method = "Get",
        # The version of the API you intent to use
        [Int]$Version = 3,
        # NOTE: Insecure. DO NOT use in production. This switch will cause
        # all checks of the certifiate to be skipped.
        [switch]$SkipCertificateCheck,
        # A short cut for looking up the id of an object.
        [string]$Reference
    )

    class MetasysEnvVars {
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

    function buildRequest {
        param (
            [string]$method = "Get",
            [string]$uri,
            [string]$body = $null,
            [string]$token = [MetasysEnvVars]::getToken(),
            [bool]$skipCertCheck = $true
        )

        return @{
            Method               = $method
            Uri                  = buildUri -path $Path
            Body                 = $body
            Authentication       = "bearer"
            Token                = ConvertTo-SecureString $token
            SkipCertificateCheck = $skipCertCheck
            ContentType          = "application/json"
        }
    }

    function executeRequest {
        param (
            [string]$method = "Get",
            [string]$uri,
            [string]$body = $null,
            [string]$token = [MetasysEnvVars]::getToken(),
            [bool]$skipCertCheck = $true
        )

        return Invoke-RestMethod @(buildRequest -uri (buildUri -path $Path) -method $Method -body $Body)
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
        }
        else {
            # attempt to renew the token to keep it fresh
            $refreshRequest = @{
                Method               = "Get"
                Uri                  = buildUri -path "/refreshToken"
                Authentication       = "bearer"
                Token                = ConvertTo-SecureString -String ([MetasysEnvVars]::getToken())
                SkipCertificateCheck = true
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

    if (($Login) -or (![MetasysEnvVars]::getToken()) -or ($ForceLogin) -or ($Site -and ($Site -ne [MetasysEnvVars]::getSite()))) {
        if (!$Site) {
            $Site = Read-Host -Prompt "Site"
        }
        if (!$UserName) {
            $UserName = Read-Host -Prompt "UserName"
        }
        $password = Read-Host -Prompt "Password" -AsSecureString

        $jsonObject = @{
            username = $UserName
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
            $secureToken = ConvertTo-SecureString -String $loginResponse.accessToken -AsPlainText
            [MetasysEnvVars]::setToken((ConvertFrom-SecureString -SecureString $secureToken))
            $env:METASYS_SITE = $Site
            [MetasysEnvVars]::setExpires($loginResponse.expires)
            $env:METASYS_VERSION = $Version
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
        $request = buildRequest -uri (buildUri -path $Path)
    }

    if ($Path) {
        $request = buildRequest -uri (buildUri -path $Path) -method $Method -body $Body
    }

    $responseObject = Invoke-WebRequest @request
    $response = $null
    if ($responseObject -and $responseObject.Content) {
        $response = ConvertFrom-Json ([String]::new($responseObject.Content))
    }
    Write-Verbose ("Http Status: " + $responseObject.StatusCode)
    [MetasysEnvVars]::setLast((ConvertTo-Json $response -Depth 15))
    return $response

}
Export-ModuleMember -Function 'Invoke-MetasysMethod'