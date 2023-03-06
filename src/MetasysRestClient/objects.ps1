## Objects Endpoint

# Get Objects


function New-HttpQueryString {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $QueryParameter
    )
    # Add System.Web
    Add-Type -AssemblyName System.Web

    # Create a http name value collection from an empty string
    $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

    foreach ($key in $QueryParameter.Keys) {
        $nvCollection.Add($key, $QueryParameter.$key)
    }


    $nvCollection.ToString()

}

<#
    Not a true camel casing routing. It just makes the first letter lowercase.
    It's expected the rest of the string is already cased properly.
#>
function CamelCase {
    param (
        $InputString
    )

    $InputString.Substring(0, 1).ToLower() + $InputString.Substring(1)
}

function BuildCommandLineParmaterDictionary {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        $BoundParameters,
        $Keys
    )

    $Dictionary = @{}
    foreach ($key in $Keys) {
        if ($BoundParameters.ContainsKey($key)) {
            $Parameter = $BoundParameters[$key]
            if ($Parameter -is [switch]) {
                $Parameter = if ($Parameter.IsPresent) { "true" } else { "false" }
            }
            $Dictionary[(CamelCase $key)] = $Parameter
        }
    }
    $Dictionary
}

function CheckForConnection {
    if ($null -eq [MetasysEnvVars]::getSiteHost() -or $null -eq ([MetasysEnvVars]::getToken()) ) {
        Write-Error "No connection to a Metasys site exists. Please connect using Connect-MetasysAccount"
        exit
    }
}


function Invoke-MsysGetObjects {
    [CmdLetBinding(PositionalBinding = $false)]
    param(

        # The parent object to serve as the root of this query. Leave empty to fetch the root of the tree.
        #
        # Alias -o
        [Alias("o")]
        [string]$ObjectId,

        [ValidateSet("object", "device", "integration", "controller", "point", "site", "navList", "extension", "folder", "reference", "server", "archive")]
        [Alias("c")]
        [string]$Classification,

        [Alias("d")]
        [int]$Depth,


        [string]$PathTo,

        [Alias("f")]
        [switch]$Flatten,
        [switch]$IncludeEffectivePermissions,
        [switch]$IncludeExtensions


    )

    DynamicParam {

        # Set the dynamic parameters' name
        $ParameterName = 'ObjectType'

        # Create the dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet, but only if aliases are found
        $arrSet = Get-ObjectTypeEnumSet
        if ($arrSet) {
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)
        }

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        # Bind the parameter to a friendly variable
        $ObjectType = $PSBoundParameters[$ParameterName]
    }

    process {

        CheckForConnection

        if ($PSBoundParameters.ContainsKey("ObjectId")) {
            $baseUrl = "/objects/$ObjectId/objects"
        }
        else {
            $baseUrl = "/objects"
        }

        $Dictionary = BuildCommandLineParmaterDictionary -BoundParameters $PSBoundParameters -Keys @("ObjectType", "Depth",
            "Classification", "PathTo", "Flatten", "IncludeExtensions", "IncludeEffectivePermissions")


        $queryString = New-HttpQueryString $Dictionary

        $uri = $baseUrl + "?" + $queryString
        Invoke-MetasysMethod $uri -ReturnBodyAsObject
    }
}


function Invoke-MsysGetObject {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ObjectId,



        [switch]$IncludeSchema
    )

    DynamicParam {

        # Set the dynamic parameters' name
        $ParameterName = 'ViewId'

        # Create the dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet, but only if aliases are found
        $arrSet = GetViewTypeEnumSet
        if ($arrSet) {
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)
        }

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        $ViewId = $PSBoundParameters[$ParameterName]
    }

    process {

        CheckForConnection

        $Dictionary = BuildCommandLineParmaterDictionary -BoundParameters $PSBoundParameters -Keys @("IncludeSchema", "ViewId")

        $queryString = New-HttpQueryString $Dictionary

        $uri = "/objects/$ObjectId" + "?" + $queryString

        Invoke-MetasysMethod $uri -ReturnBodyAsObject
    }
}




Set-Alias -Name imgos -Value Invoke-MesysGetObjects
Set-Alias -Name imgo -Value Invoke-MsysGetObject

Export-ModuleMember -Function "Invoke-MsysGetObjects", "Invoke-MsysGetObject"

Export-ModuleMember -Alias "imgos", "imgo"
