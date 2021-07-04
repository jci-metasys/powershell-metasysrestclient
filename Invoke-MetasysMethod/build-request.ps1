# The uri can be
# * relative to the https://hostname/api/v{next}
# * absolute (eg https://hostname/api/v{next}/objects/{id}/attributes/presentValue)
function buildRequest {
    param (
        [string]$method = "Get",
        [string]$uri,
        [string]$body = $null,
        [SecureString]$token,
        [string]$version
    )

    $request = @{
        Method               = $method
        Uri                  = buildUri -path $Path -version $version
        Body                 = $body
        Authentication       = "bearer"
        Token                = $token
        SkipCertificateCheck = $SkipCertificateCheck
        ContentType          = "application/json"
        Headers              = @{}
    }

    if ($Headers) {
        foreach ($header in $Headers.GetEnumerator()) {
            $request.Headers[$header.Key] = $header.Value
        }
    }

    return $request
}
