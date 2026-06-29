# The uri can be
# * relative to the https://hostname/api/v{next}
# * absolute (eg https://hostname/api/v{next}/objects/{id}/attributes/presentValue)

Set-StrictMode -Version 3
function buildRequest {
    param (
        [string]$method = "Get",
        [Parameter(Mandatory = $true)]
        [string]$uri,
        [string]$body = $null,
        [SecureString]$token,
        [switch]$skipCertificateCheck,
        [Hashtable]$headers
    )

    $request = @{
        Method               = $method
        Uri                  = $uri
        Body                 = $body
        SkipCertificateCheck = $skipCertificateCheck
        ContentType          = "application/json; charset=utf-8"
        Headers              = @{}
    }

    if ($token) {
        $request.Token = $token
        $request.Authentication = "bearer"
    }

    # Hint to servers that we prefer encodings PowerShell can auto-decompress.
    # Servers may ignore this and send br or other encodings anyway.
    $request.Headers["Accept-Encoding"] = "gzip, deflate"

    if ($headers) {
        foreach ($header in $Headers.GetEnumerator()) {
            $request.Headers[$header.Key] = $header.Value
        }
    }

    return $request
}
