
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

    $firstDevice = $deviceResponse.items[0]
    $firstDeviceId = $firstDevice.id

    $matchingObjects = (Invoke-MetasysMethod -Method Get `
        -Path /objects/$firstDeviceId/objects?objectType=$ObjectType`&flatten=true `
        -ReturnBodyAsObject) | Select-Object -ExpandProperty items `
        | Where-Object objectType -EQ $ObjectType

    $matchingObjects | Select-Object -Property id, name, itemReference

}


Set-Alias -Name ifo -Value Invoke-MetasysFindObject

Export-ModuleMember -Function 'Invoke-MetasysFindObject'
Export-ModuleMember -Alias 'ifo'
