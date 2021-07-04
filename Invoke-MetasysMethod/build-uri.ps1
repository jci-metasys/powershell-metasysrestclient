# The path can be
# * relative to the https://hostname/api/v{next}
# * absolute (eg https://hostname/api/v{next}/objects/{id}/attributes/presentValue)
function buildUri {
    param (
        [string]$siteHost = [MetasysEnvVars]::getSiteHost(),
        [int]$version = [MetasysEnvVars]::getVersion(),
        [string]$baseUri = "api",
        [string]$path
    )

    $uri = [Uri]::new($path, [UriKind]::RelativeOrAbsolute)
    if ($uri.IsAbsoluteUri) {
        return $uri
    }

    $fullPath = "https://$siteHost/$([Path]::Join($baseUri, "v" + $version, $path))"
    return [Uri]::new($fullPath)
}
