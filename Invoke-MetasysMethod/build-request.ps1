# The uri can be
# * relative to the https://hostname/api/v{next}
# * absolute (eg https://hostname/api/v{next}/objects/{id}/attributes/presentValue)

Set-StrictMode -Version 3
function buildRequest {
    param (
        [string]$method = "Get",
        [string]$uri = $null,
        [string]$body = $null,
        [SecureString]$token,
        [string]$version,
        [switch]$skipCertificateCheck,
        [Hashtable]$headers
    )

    $request = @{
        Method               = $method
        Uri                  = $uri ?? (buildUri -path $Path -version $version)
        Body                 = $body
        SkipCertificateCheck = $skipCertificateCheck
        ContentType          = "application/json; charset=utf-8"
        Headers              = @{}
    }

    if ($token) {
        $request.Token = $token
        $request.Authentication = "bearer"
    }

    if ($headers) {
        foreach ($header in $Headers.GetEnumerator()) {
            $request.Headers[$header.Key] = $header.Value
        }
    }

    return $request
}
