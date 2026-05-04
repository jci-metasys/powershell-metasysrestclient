
function Invoke-MetasysFindObject {
    param(
        [Parameter(Position = 0)]
        [string]$ObjectType
    )

    if (!$ObjectType.StartsWith("objectTypeEnumSet.")) {
        $ObjectType = "objectTypeEnumSet.$ObjectType"
    }

    $deviceResponse = Invoke-MetasysMethod -Method Get `
        -Path /networkDevices?classification=device -ReturnBodyAsObject

    if ($deviceResponse.items.Count -eq 0) {
        $deviceResponse = Invoke-MetasysMethod -Method Get `
            -Path /networkDevices?classification=server -ReturnBodyAsObject
    }

    if ($deviceResponse.items.Count -eq 0) {
        return
    }

    $firstDevice = $deviceResponse.items[0]
    $firstDeviceId = $firstDevice.id

    $matchingObjects = (Invoke-MetasysMethod -Method Get `
            -Path /objects/$firstDeviceId/objects?objectType=$ObjectType`&flatten=true `
            -ReturnBodyAsObject) | Select-Object -ExpandProperty items `
    | Where-Object objectType -EQ $ObjectType

    $result = $matchingObjects | Select-Object -Property id, name, itemReference

    $metasysHost = [MetasysEnvVars]::getSiteHost()
    CacheObjectIds -MetasysHost $metasysHost -Objects $result

    $result

}


Set-Alias -Name ifo -Value Invoke-MetasysFindObject

Export-ModuleMember -Function 'Invoke-MetasysFindObject'
Export-ModuleMember -Alias 'ifo'
