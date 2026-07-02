
function GetCachePath {
    param (
        [string]$MetasysHost
    )
    # Determine the cache directory based on the OS
    $CacheDirName = "MetasysRestClient"
    if ($IsWindows) {
        $cacheDir = [System.IO.Path]::Combine($env:LOCALAPPDATA, $CacheDirName)
    }
    elseif ($IsLinux) {
        $cacheDir = [System.IO.Path]::Combine($env:HOME, ".cache", $CacheDirName)
    }
    elseif ($IsMacOS) {
        $cacheDir = [System.IO.Path]::Combine($env:HOME, "Library", "Caches", $CacheDirName)
    }
    else {
        throw "Unsupported OS"
    }

    # Create the cache directory if it doesn't exist
    if (-not (Test-Path -Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir | Out-Null
    }

    # Create a file in the cache directory
    $filePath = [System.IO.Path]::Combine($cacheDir, "$MetasysHost-cachedObjectIds.json")
    if (-not (Test-Path -Path $filePath)) {
        New-Item -ItemType File -Path $filePath -Force | Out-Null
    }

    return $filePath
}

function LookupCachedReferences {
    param(
        [string]$wordToComplete,
        [System.Management.Automation.Language.CommandAst]$commandAst,
        [int]$cursorPosition,
        [System.Management.Automation.CommandCompletionOptions]$options,
        [System.Management.Automation.Language.Ast]$fakeBoundParameters
    )

    $metasysHost = [MetasysEnvVars]::getSiteHost()
    $cache = GetCacheObject -MetasysHost $metasysHost
    $cache.Keys
}

function GetCacheObject {
    param (
        [string]$MetasysHost
    )
    $cacheFile = GetCachePath -MetasysHost $MetasysHost

    $cacheContents = ([System.IO.File]::ReadAllText($cacheFile)).Trim()

    $cache = if ($cacheContents -eq "") {
        @{}
    }
    else {
        $cacheContents | ConvertFrom-Json -AsHashtable
    }

    $cache
}

function GetObjectId {
    param (
        [string]$MetasysHost,
        [string]$ItemReference
    )
    $cache = GetCacheObject -MetasysHost $MetasysHost
    $cache[$ItemReference]
}

function CacheObjectIds {
    param (
        [string]$MetasysHost,
        # It is expected that every object has an `id` and `itemReference`
        [Array]$Objects
    )

    $cache = GetCacheObject -MetasysHost $MetasysHost
    $cacheFile = GetCachePath -MetasysHost $MetasysHost

    foreach ($object in $Objects) {
        $cache[$object.itemReference] = $object.id
    }

    [System.IO.File]::WriteAllText($cacheFile, (ConvertTo-Json -InputObject $cache))

}

function CacheObjectId {
    param (
        [string]$MetasysHost,
        [string]$ItemReference,
        [string]$ObjectId
    )

    $cache = GetCacheObject -MetasysHost $MetasysHost
    $cacheFile = GetCachePath -MetasysHost $MetasysHost

    $cache[$ItemReference] = $ObjectId

    [System.IO.File]::WriteAllText($cacheFile, (ConvertTo-Json -InputObject $cache))
}

function Remove-MetasysCache {
    param(
        [string]$MetasysHost
    )
    $cachePath = GetCachePath -MetasysHost $MetasysHost
    try {
        Remove-Item -Path $cachePath -Force
    }
    catch {

    }
}


function Invoke-MetasysReadAttribute {
    <#
    .SYNOPSIS
        Read the specified attribute of the specified object.

    .DESCRIPTION
        Reads a single attribute value from a Metasys object and returns it to the pipeline.

        The object may be identified by object ID (-ObjectId) or by fully-qualified item reference
        (-ItemReference). When using -ItemReference, the resolved object ID is cached locally
        so subsequent calls for the same reference skip the lookup API call.

        AttributeId defaults to 'presentValue' when not specified.

        Non-normal conditions on the attribute are reported after the value:
          - A WARNING is written if the condition indicates something unexpected (e.g. reliability fault).
          - An INFORMATION message is written if the only condition is a non-default write priority.
            To see these messages, pass -InformationAction Continue or set
            $InformationPreference = 'Continue'.

    .PARAMETER ObjectId
        The object ID of the Metasys object to read from.

    .PARAMETER ItemReference
        The fully-qualified item reference (e.g. site:device.AV1) of the object to read from.
        Tab completion is available from the local object ID cache.

    .PARAMETER AttributeId
        The attribute to read. Defaults to 'presentValue'.

    .OUTPUTS
        The attribute value (type depends on the Metasys data type of the attribute).

    .EXAMPLE
        Invoke-MetasysReadAttribute -ObjectId ba1a703a-1e96-54ae-9ae6-9590a55c2e4a

        Reads the presentValue of the object with the given object ID.

    .EXAMPLE
        ira welch12:welch12/AV1

        Reads the presentValue using the item reference. The alias 'ira' and positional
        parameter binding mean you can type this immediately after 'ira <Tab>'.

    .EXAMPLE
        ira welch12:welch12/AV1 -AttributeId name

        Reads the 'name' attribute of the object.

    .EXAMPLE
        ira welch12:welch12/AV1 -InformationAction Continue

        Reads presentValue and also displays informational messages such as a non-default
        write priority condition.

    #>
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "ObjectId")]
        [string]$ObjectId,
        [Parameter(Mandatory = $true, ParameterSetName = "ItemReference", Position = 0)]
        [string]$ItemReference,

        [Parameter(Mandatory = $false)]
        [String]$AttributeId = "presentValue"
    )

    $shouldReadAttribute = $true

    if ($PSCmdlet.ParameterSetName -eq 'ItemReference') {
        $MetasysHost = [MetasysEnvVars]::getSiteHost()
        $ObjectId = GetObjectId -MetasysHost $MetasysHost -ItemReference $ItemReference

        if ($null -eq $ObjectId -or $ObjectId -eq "") {

            # Use a separate variable to avoid type coercion: $ObjectId is [string]-typed,
            # so assigning an OrderedHashtable would silently coerce it to a string.
            $identifiersResponse = imm "/objects/identifiers?fqr=$ItemReference" -ReturnBodyAsObject
            if ($identifiersResponse -isnot [string]) {
                Write-Error "The reference '$ItemReference' was not found."
                $shouldReadAttribute = $false
            }
            else {
                $ObjectId = $identifiersResponse
                CacheObjectId -MetasysHost $MetasysHost -ItemReference $ItemReference -ObjectId $ObjectId
            }
        }
    }

    if ($shouldReadAttribute) {
        $response = Invoke-MetasysMethod "/objects/$ObjectId/attributes/$AttributeId`?includeSchema=true"

        $result = [MetasysValue]::ParseReadAttributeResponse($response)
        $result.Value

        $responseParsed = $response | ConvertFrom-Json -AsHashtable -Depth 20

        if (([System.Management.Automation.OrderedHashtable]$responseParsed.condition).ContainsKey($AttributeId)) {
            $conditionDetail = $responseParsed.condition[$AttributeId]
            $conditionKeys = @($conditionDetail.Keys)
            $message = "$AttributeId has non-normal conditions $(ConvertTo-Json $conditionDetail)"
            if ($conditionKeys.Count -eq 1 -and $conditionKeys[0] -eq "priority") {
                Write-Information $message
            }
            else {
                Write-Warning $message
            }
        }
    }
}



function Invoke-MetasysGetObjectView {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "ObjectId")]
        [string]$ObjectId,
        [Parameter(Mandatory = $true, ParameterSetName = "ItemReference")]
        [string]$ItemReference,
        [Parameter(Mandatory = $false)]
        [string]$View = $null
    )
    if ($PSCmdlet.ParameterSetName -eq 'ItemReference') {
        $MetasysHost = [MetasysEnvVars]::getSiteHost()
        $ObjectId = GetObjectId -MetasysHost $MetasysHost -ItemReference $ItemReference

        if ($null -eq $ObjectId -or $ObjectId -eq "") {

            $ObjectId = imm "/objects/identifiers?fqr=$ItemReference" -ReturnBodyAsObject
            if ($null -eq $ObjectId -or $ObjectId.GetType().Name -ne "String") {
                Write-Error "The reference '$ItemReference' was not found."
                return
            }
            CacheObjectId -MetasysHost $MetasysHost -ItemReference $ItemReference -ObjectId $ObjectId
        }
    }

    $viewPath = if ($View) { "?viewId=$View" } else { "" }

    $path = "/objects/$ObjectId$viewPath"

    $result = Invoke-MetasysMethod $path -ReturnBodyAsObject

    if ($result.ContainsKey("item")) {
        $result.item
    }
}


function Invoke-MetasysDiscoverObjects {
    param(
        [ArgumentCompleter({ Get-MetasysCachedItemReferences @args })]
        [string]$ItemReference
    )
    $metasysHost = [MetasysEnvVars]::getSiteHost()
    $objectId = GetObjectId -MetasysHost $metasysHost -ItemReference $ItemReference
    if ($null -eq $objectId) {
        $objectId = Invoke-MetasysMethod -Path "/objects/identifiers?fqr=$ItemReference" -ReturnBodyAsObject
    }

    $objects = Invoke-MetasysMethod `
        -Path "/objects/$objectId/objects?depth=-1`&flatten=true" `
        -ReturnBodyAsObject | Select-Object -ExpandProperty items

    CacheObjectIds -MetasysHost $metasysHost -Objects $objects

    "Discovery complete. $($objects.Count) objects found."
}



Set-Alias -Name ira -Value Invoke-MetasysReadAttribute

Export-ModuleMember -Function 'Invoke-MetasysReadAttribute'
Export-ModuleMember -Alias 'ira'

Export-ModuleMember -Function 'Remove-MetasysCache'
Export-ModuleMember -Function 'Invoke-MetasysDiscoverObjects'
