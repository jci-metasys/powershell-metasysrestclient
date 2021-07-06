# This is local sanity check test script.


$response = Invoke-MetasysMethod /enumerations -SiteHost welchoas

if ($response -isnot [String]) {
    Write-Error "Expected response to be a stringt not $($response.GetType())"
}

$response = Invoke-MetasysMethod /enumerations -SiteHost welchoas -ReturnBodyAsObject

if ($response -isnot [PSCustomObject] -and $response -isnot [Hashtable]) {
    Write-Error "Expected resposne as object to be PSCustomObject or Hashtable, not $($response.GetType()))"
}
