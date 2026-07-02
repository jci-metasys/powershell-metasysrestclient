# This is local sanity check test script.
# Run Connect-MetasysAccount first to establish a session before running this script.

Import-Module ./src/MetasysRestClient -Force

$response = Invoke-MetasysMethod /enumerations -ErrorAction Stop

if ($response -isnot [String]) {
    Write-Error "Expected response to be a string not $($response.GetType())"
}
else {
    Write-Output "Success"
}

$response = Invoke-MetasysMethod /enumerations -ReturnBodyAsObject -ErrorAction Stop

if ($response -isnot [PSCustomObject] -and $response -isnot [Hashtable]) {
    Write-Error "Expected response as object to be PSCustomObject or Hashtable, not $($response.GetType()))"
}
else {
    Write-Output "Success"
}
