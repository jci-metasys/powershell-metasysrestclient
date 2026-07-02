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
    if ($Host.PrivateData) {
        $Host.PrivateData.DebugBackgroundColor = $backgroundColor
        $Host.PrivateData.ErrorBackgroundColor = $backgroundColor
        $Host.PrivateData.WarningBackgroundColor = $backgroundColor
        $Host.PrivateData.VerboseBackgroundColor = $backgroundColor
    }

}


function invokeHttpRequest {
    param(
        [string]$uri,
        [string]$method,
        [string]$body,
        [string]$token,
        [switch]$skipCertificateCheck,
        [hashtable]$headers = @{},
        [string]$outputFile = ""
    )

    $handler = [System.Net.Http.HttpClientHandler]::new()
    $handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
    if ($skipCertificateCheck) {
        $handler.ServerCertificateCustomValidationCallback = [System.Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator
    }
    $httpReq = $null
    $httpResp = $null
    $client = [System.Net.Http.HttpClient]::new($handler)
    try {
        $client.DefaultRequestHeaders.TryAddWithoutValidation("Authorization", "Bearer $token") | Out-Null
        foreach ($key in $headers.Keys) {
            $client.DefaultRequestHeaders.TryAddWithoutValidation($key, $headers[$key]) | Out-Null
        }

        $httpMethod = [System.Net.Http.HttpMethod]::new($method.ToUpper())
        $httpReq = [System.Net.Http.HttpRequestMessage]::new($httpMethod, $uri)
        if ($body) {
            $httpReq.Content = [System.Net.Http.StringContent]::new($body, [System.Text.Encoding]::UTF8, "application/json")
        }

        # ResponseHeadersRead returns once headers arrive; body is not buffered in memory,
        # so large payloads do not cause OverflowException.
        $httpResp = $client.SendAsync($httpReq, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()

        $statusCode = [int]$httpResp.StatusCode
        $statusDescription = $httpResp.ReasonPhrase

        $responseHeaders = @{}
        foreach ($h in $httpResp.Headers) {
            $responseHeaders[$h.Key] = $h.Value -join ", "
        }
        foreach ($h in $httpResp.Content.Headers) {
            $responseHeaders[$h.Key] = $h.Value -join ", "
        }

        # AutomaticDecompression strips gzip/deflate from ContentEncoding after handling them.
        # identity means no encoding. Anything else left (e.g. br, zstd) is unhandled binary.
        $contentEncoding = @($httpResp.Content.Headers.ContentEncoding | Where-Object { $_ -ne 'identity' })
        $isBinary = $contentEncoding.Count -gt 0

        # Binary with no output file: return immediately without downloading the body.
        if ($isBinary -and -not $outputFile) {
            return [PSCustomObject]@{
                StatusCode        = $statusCode
                StatusDescription = $statusDescription
                Headers           = $responseHeaders
                Content           = $null
                ContentEncoding   = $contentEncoding -join ", "
            }
        }

        # Content-Length may be absent for chunked transfers.
        $totalBytes = $httpResp.Content.Headers.ContentLength
        $stream = $httpResp.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $buffer = [byte[]]::new(81920)
        $totalRead = [long]0

        $reportProgress = {
            if ($totalBytes -gt 0) {
                $pct = [int]([Math]::Min(($totalRead / $totalBytes) * 100, 100))
                Write-Progress -Activity "Downloading" `
                    -Status "$([int]($totalRead / 1KB)) KB / $([int]($totalBytes / 1KB)) KB" `
                    -PercentComplete $pct
            } else {
                Write-Progress -Activity "Downloading" `
                    -Status "$([int]($totalRead / 1KB)) KB received" `
                    -PercentComplete -1
            }
        }

        if ($isBinary) {
            # Stream directly to file — no MemoryStream, no double-allocation.
            $fileStream = [System.IO.FileStream]::new($outputFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
            try {
                $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
                while ($bytesRead -gt 0) {
                    $fileStream.Write($buffer, 0, $bytesRead)
                    $totalRead += $bytesRead
                    & $reportProgress
                    $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
                }
            }
            finally {
                Write-Progress -Activity "Downloading" -Completed
                $fileStream.Dispose()
                $stream.Dispose()
            }
            return [PSCustomObject]@{
                StatusCode        = $statusCode
                StatusDescription = $statusDescription
                Headers           = $responseHeaders
                Content           = $null
                ContentEncoding   = $contentEncoding -join ", "
            }
        }

        # Text/JSON: buffer in MemoryStream.
        $accumulator = [System.IO.MemoryStream]::new()
        try {
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            while ($bytesRead -gt 0) {
                $accumulator.Write($buffer, 0, $bytesRead)
                $totalRead += $bytesRead
                & $reportProgress
                $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            }
        }
        finally {
            Write-Progress -Activity "Downloading" -Completed
            $stream.Dispose()
        }

        $bytes = $accumulator.ToArray()
        $accumulator.Dispose()

        return [PSCustomObject]@{
            StatusCode        = $statusCode
            StatusDescription = $statusDescription
            Headers           = $responseHeaders
            Content           = [System.Text.Encoding]::UTF8.GetString($bytes)
            ContentEncoding   = $null
        }
    }
    finally {
        if ($null -ne $httpResp) { $httpResp.Dispose() }
        if ($null -ne $httpReq) { $httpReq.Dispose() }
        $client.Dispose()
    }
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
        This function allows you to call methods of the Metasys REST API. Once a session is established (on the first invocation) the session state is maintained in the terminal session. This allows you to make additional calls with less boilerplate text necessary for each call.

    .OUTPUTS
        System.String
            The payloads from Metasys are formatted JSON strings. This is the default return type for this function.

        PSObject, Hashtable
            If the switch `ReturnBodyAsObject` is set then this function attempts to convert the response to a custom object. In some cases, the JSON string may contain properties that only differ in casing and can't be converted to a PSObject. In such cases, a Hashtable is returned instead. Note: This parameter only applies if the response content type is JSON. Otherwise it is ignored.

    .EXAMPLE
        Invoke-MetasysMethod /objects/$id

        Reads the default view of the specified object assuming $id contains a valid object identifier

    .EXAMPLE
        Invoke-MetasysMethod /alarms

        This will read the first page of alarms from the site.

    .EXAMPLE
        Invoke-MetasysMethod -Method Put /objects/$id/commands/adjust -Body '{ "parameters": [72.5] }'

        This example will send the adjust command to the specified object (assuming a valid id is stored in $id, and v4 of the API).

    .LINK

        https://github.com/jci-metasys/powershell-metasysrestclient

    #>

    [CmdletBinding(PositionalBinding = $false)]
    param(
        # The relative or absolute url for an endpont. For example: /alarms
        # All of the urls are listed in the API Documentation
        [Parameter(Position = 0)]
        [string]$Path,
        # The payload to send with your request.
        #
        # Alias: -b
        [Parameter(ValueFromPipeline = $true)]
        [Alias("b")]
        [string]$Body,
        # The HTTP Method you are sending.
        #
        # Aliases: -m, -verb
        [Alias("verb", "m")]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = "Get",
        # The version of the API you intend to use. Typically you do not need to specify anything for this parameter as this command will use whatever version was specified when you ran `Connect-MetasysAccount`. However, you may wish to use this paramter if you want to invoke an operation at a different version than the one used to connect.
        #
        # Acceptable values: 2, 3, 4, 5
        # Alias: -v
        [Alias("v")]
        [string]$Version,
        # A collection of headers to include in the request
        #
        # Alias: -h
        [Alias("h")]
        [hashtable]$Headers = @{},
        # Return the response as PSObject or Hashtable instead of JSON string
        # Aliases: -o, -object
        [Alias("o", "object")]
        [Switch]$ReturnBodyAsObject,
        # Includes the response headers in the output
        #
        # Alias: -rh
        [Alias("rh")]
        [Switch]$IncludeResponseHeaders,
        # Write the response body to this file path. Use when the response is binary.
        #
        # Alias: -of
        [Alias("of")]
        [string]$OutFile,

        # Add a subscription for this resource. Pass a `stream id` as the value
        # of this parameter. For example `0915342b-4557-401e-a061-237d0bced15d` (
        # assuming this is the stream id passed to you in the hello event of your stream
        # )
        #
        # This is identical to including `METASYS-SUBSCRIBE` in `Headers` parameter.
        # If you use both `Subscribe` and `Headers` the `Subscribe` parameter value is
        # used
        # Alias: s
        [Alias("s")]
        [Guid]$Subscribe
    )

    BEGIN {
        Set-Variable -Name fiveMinutes -Value ([TimeSpan]::FromMinutes(5)) -Option Constant

        setBackgroundColorsToMatchConsole


        assertPowershellCore

        if (!$Path) {
            Write-Information "Path not supplied. Please enter a path"
            $Path = Read-Host -Prompt "Path"
        }

        # Read SkipCertificateCheck from environment
        $SkipCertificateCheck = [MetasysEnvVars]::getSkipCertificateCheck()

        $uri = [Uri]::new($path, [UriKind]::RelativeOrAbsolute)
        if ($uri.IsAbsoluteUri) {
            $versionSegment = $uri.Segments[2]
            $versionNumber = $versionSegment.SubString(1, $versionSegment.Length - 2)
            if ($Version -ne "" -and $versionNumber -ne $Version) {
                Write-Error "An absolute url was given for Path and it specifies a version ('$versionNumber') that conflicts with Version ('$Version')"
                continue
            }
        }

        If ($Version -eq "") {
            # Use the version from last cma call, else the default api version (if set), else latest version
            if ($env:METASYS_VERSION) {
                $Version = $env:METASYS_VERSION
            }
            else {
                $Version = (Get-MetasysDefaultApiVersion) ?? (Get-MetasysLatestVersion)
                Write-Information "No version specified. Defaulting to v$Version"
            }
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
                        Write-Information "Session has expired. Trying to reconnect with this command:"
                        Write-Information "Connect-MetasysAccount -SiteHost $([MetasysEnvVars]::getSiteHost()) -UserName $([MetasysEnvVars]::getUserName()) -Version $($Version) `
-                         -SkipCertificateCheck:$($SkipCertificateCheck)"
                        Connect-MetasysAccount -SiteHost ([MetasysEnvVars]::getSiteHost()) -UserName ([MetasysEnvVars]::getUserName()) -Version $Version `
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
                    $refreshRequest = buildRequest -uri $uri -token ([MetasysEnvVars]::getToken()) -skipCertificateCheck:$SkipCertificateCheck

                    try {
                        Write-Debug "Attempting to refresh access token"
                        $refreshResponse = Invoke-RestMethod @refreshRequest
                        [MetasysEnvVars]::setExpires($refreshResponse.expires)
                        [MetasysEnvVars]::setTokenAsPlainText($refreshResponse.accessToken)
                        Write-Debug "Refresh token successful"
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

        if ($Subscribe) {
            $Headers['Metasys-Subscribe'] = $Subscribe
        }

        $response = $null

        Write-Debug "Attempting request"

        $resolvedOutputFile = ""
        if ($OutFile) {
            $resolvedOutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
        }

        $result = $null
        try {
            $result = invokeHttpRequest -uri $uri.ToString() -method $Method.ToString() -body $Body `
                -token ([MetasysEnvVars]::getTokenAsPlainText()) -skipCertificateCheck:$SkipCertificateCheck `
                -headers $Headers -outputFile $resolvedOutputFile
        }
        catch {
            Write-Error $_
            return
        }

        if ($result -and $result.ContentEncoding) {
            if ($OutFile) {
                $resolvedOutputFile
            } else {
                Write-Warning "The response is $($result.ContentEncoding)-encoded binary. Use -OutFile to save it, e.g.:"
                Write-Warning "    imm $Path -OutFile output.bin"
            }
            return
        }

        $statusCode = $result.StatusCode
        $statusDescription = $result.StatusDescription
        $responseHeaders = $result.Headers
        $response = $result.Content

        $contentType = "unknown" # one of json, text, unknown
        $contentLength = 0
        if ($responseHeaders["Content-Length"]) {
            [Int]::TryParse($responseHeaders["Content-Length"], [ref] $contentLength) | Out-Null
        } else {
            $contentLength = if ($null -ne $response) { $response.Length } else { 0 }
        }

        if ($responseHeaders["Content-Type"] -like "*json*" -or $contentLength -eq 0 -or $statusCode -eq 204 -or $statusCode -ge 400) {
            $contentType = "json"
        }
        elseif ($responseHeaders["Content-Type"] -like "text*") {
            $contentType = "text"
        }
        else {
            $contentType = "unknown"
            Write-Warning "Unexpected content type: $($responseHeaders["Content-Type"])"
        }

        # Only overwrite the last response if content is JSON
        if ($null -ne $response -and $contentType -eq "json") {
            [MetasysEnvVars]::setLast($response)
            [MetasysEnvVars]::setHeaders($responseHeaders)
            [MetasysEnvVars]::setStatus($statusCode, $statusDescription)
        }

        if ($ReturnBodyAsObject.IsPresent -and $null -ne $response -and $contentType -eq "json") {
            Get-LastMetasysResponseBodyAsObject
        }
        elseif ($null -ne $response) {
            if ($contentType -eq "json") {
                if ($IncludeResponseHeaders) {
                    Show-LastMetasysFullResponse
                }
                else {
                    Show-LastMetasysResponseBody
                }
            }
            elseif ($contentType -eq "text") {
                if ($IncludeResponseHeaders) {
                    "$statusCode ($statusDescription)"
                    $responseHeaders.Keys | ForEach-Object { "$_`: $($responseHeaders[$_])" }
                    ""
                    $response
                }
                else {
                    $response
                }
            }
        }
    }

}



function Show-LastMetasysAccessToken {
    ConvertFrom-SecureString -AsPlainText -SecureString ([MetasysEnvVars]::getToken())
}

function Show-LastMetasysHeaders {

    $response = ""
    $headers = ConvertFrom-Json ([MetasysEnvVars]::getHeaders())
    foreach ($header in $headers.PSObject.Properties) {
        $response += "$($header.Name): $($header.Value -join ',')" + "`n"
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

    # Always use -AsHashtable since we have some enum sets that
    # have keys that vary only in casing in the same enum set.
    try {
        ConvertFrom-Json -AsHashtable -InputObject $json
    }
    catch {
        # apparently this wasn't JSON so leave it as is
        $json
    }

}

function Show-LastMetasysResponseBody {
    $body = [MetasysEnvVars]::getLast()
    if ($body) {
        ConvertFrom-JsonSafely $body | ConvertTo-Json -Depth 20
    }
}

function Show-LastMetasysFullResponse {
    "$(Show-LastMetasysStatus)`n$(Show-LastMetasysHeaders)`n$(Show-LastMetasysResponseBody)"
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
