# The path can be
# * relative to the https://hostname/api/v{next}
# * absolute (eg https://hostname/api/v{next}/objects/{id}/attributes/presentValue)
function buildUri {
    param (
        [Parameter(Mandatory = $true)]
        [string]$siteHost,
        [Parameter(Mandatory = $true)]
        [string]$version,
        [Parameter(Mandatory = $true)]
        [string]$path
    )

    $uri = [Uri]::new($path, [UriKind]::RelativeOrAbsolute)
    if ($uri.IsAbsoluteUri) {
        return $uri
    }

    $fullPath = "https://$siteHost/$([Path]::Join("api", "v" + $version, $path))"
    return [Uri]::new($fullPath)
}
