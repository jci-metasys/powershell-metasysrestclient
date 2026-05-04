
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
        Read the specified attribute of the specified object

    .DESCRIPTION
        This function calls the get attribute value operation using the object id and
        attribute id specified.

    .OUTPUTS
        System.String
            The payloads from Metasys are formatted JSON strings. This is the default return type for this function.

    .EXAMPLE
        Invoke-MetasysReadAttribute -ObjectId ba1a703a-1e96-54ae-9ae6-9590a55c2e4a -AttributeId name

        This will read the attribute `name` of the object and return its value.

        MOLEX LIGHT POWER

    #>
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "ObjectId")]
        [string]$ObjectId,
        [Parameter(Mandatory = $true, ParameterSetName = "ItemReference")]
        [string]$ItemReference,

        [Parameter(Mandatory = $true)]
        [String]$AttributeId
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
            Write-Warning ("$AttributeId has non-normal conditions $(ConvertTo-Json $responseParsed.condition[$AttributeId])")
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
