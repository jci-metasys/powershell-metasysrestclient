using namespace System.Text.Json.Nodes


function ParseMetasysValue {
    param (
        [JsonNode]$Value,
        [JsonNode]$Schema
    )

    $metasysType = $Schema["metasysType"]
    if ($null -eq $metasysType) {
        return $null
    }

    switch ($metasysType) {
        "none" { return [NoneValue]::Instance }
        "bool" { return [BoolValue]::new($Value.GetValue[bool]()) }
        "ulong" { return [ULongValue]::new($Value.GetValue[uint]()) }
        "long" { return [LongValue]::new($Value.GetValue[int]()) }
        "float" { return [FloatValue]::new($Value.GetValue[float]()) }
        "double" { return [DoubleValue]::new($Value.GetValue[double]()) }
        "octetString" { return [OctetStringValue]::Parse($Value.GetValue[string]()) }
        "string" { return [StringValue]::new($Value.GetValue[string]()) }
        "bitString" { return [BitStringValue]::Parse($Value.GetValue[string]()) }
        "enum" { return [EnumValue]::Parse($Value.GetValue[string]()) }
        "enumMemberId" { return [EnumMemberIdValue]::new($Value.GetValue[uint]()) }
        default { return [NoneValue]::Instance }
    }
}


class MetasysValue {

    [object]$Value

    # Parse a read attribute response
    static [MetasysValue] ParseReadAttributeResponse([string]$readAttributeResponse) {
        $response = [JsonNode]::Parse($readAttributeResponse)


        # We expect a single property with a schema for that property
        $item = $response["item"]
        $enumerator = $item.GetEnumerator()
        if ($enumerator.MoveNext()) {
            $attributeName = $enumerator.Current.Key
            $attributeValueNode = $enumerator.Current.Value
        }
        else {
            throw "No attribute value found"
        }

        $attributeSchema = $response["schema"]["properties"][$attributeName]
        return ParseMetasysValue -Value $attributeValueNode -Schema $attributeSchema
    }
}

<#
.SYNOPSIS
    Represents an instance of the None data type
#>
class NoneValue : MetasysValue {
    <#
        .SYNOPSIS
            Represents the one and only instance of None
    #>
    static [NoneValue]$Instance = [NoneValue]::new()
}

class BoolValue : MetasysValue {
    hidden [bool] $_value

    hidden static $ValueDefinition = @{
        TypeName   = 'BoolValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._value
        }
    }

    BoolValue([bool]$value) {
        $this._value = $value;
        $Definition = [BoolValue]::ValueDefinition
        Update-TypeData @Definition
    }

    [bool] ToBoolean() {
        return $this._value
    }

    [string] ToString() {
        return $this._value.ToString()
    }
}

<#
.SYNOPSIS
    Represents a 32-bit unsigned integer
#>
class ULongValue : MetasysValue {
    hidden [uint] $_value

    hidden static $ValueDefinition = @{
        TypeName   = 'ULongValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._value
        }
    }

    ULongValue([uint]$value) {
        $this._value = $value;
        $Definition = [ULongValue]::ValueDefinition
        Update-TypeData @Definition
    }

    [uint] ToUInt32() {
        return $this._value
    }

    [string] ToString() {
        return $this._value.ToString()
    }
}


<#
.SYNOPSIS
    Represents a 32-bit signed integer
#>
class LongValue : MetasysValue {
    hidden [int] $_value

    hidden static $ValueDefinition = @{
        TypeName   = 'LongValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._value
        }
    }

    LongValue([int]$value) {
        $this._value = $value;
        $Definition = [LongValue]::ValueDefinition
        Update-TypeData @Definition
    }

    [int] ToInt32() {
        return $this._value
    }

    [string] ToString() {
        return $this._value.ToString()
    }
}


<#
.SYNOPSIS
    Represents a 32-bit floating point number
#>
class FloatValue : MetasysValue {
    hidden [float] $_value

    hidden static $ValueDefinition = @{
        TypeName   = 'FloatValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._value
        }
    }

    FloatValue([float]$value) {
        $this._value = $value;
        $Definition = [FloatValue]::ValueDefinition
        Update-TypeData @Definition
    }

    [float] ToFloat() {
        return $this._value
    }

    [string] ToString() {
        return $this._value.ToString()
    }
}



<#
.SYNOPSIS
    Represents a 64-bit floating point number
#>
class DoubleValue : MetasysValue {
    hidden [double] $_value

    hidden static $ValueDefinition = @{
        TypeName   = 'DoubleValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._value
        }
    }

    DoubleValue([double]$value) {
        $this._value = $value;
        $Definition = [DoubleValue]::ValueDefinition
        Update-TypeData @Definition
    }

    [double] ToDouble() {
        return $this._value
    }

    [string] ToString() {
        return $this._value.ToString()
    }
}



<#
.SYNOPSIS
    Represents an array of bytes
#>
class OctetStringValue : MetasysValue {
    hidden [byte[]] $_value

    hidden static $ValueDefinition = @{
        TypeName   = 'OctetStringValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return [byte[]]$this._value
        }
    }

    OctetStringValue([byte[]]$value) {
        $this._value = $value;
        $Definition = [OctetStringValue]::ValueDefinition
        Update-TypeData @Definition
    }

    [string] ToString() {
        return $this._value.ToString()
    }

    static [OctetStringValue] Parse([string]$HexString) {
        # Calculate the number of bytes
        $byteCount = $HexString.Length / 2

        # Initialize the byte array with the calculated size
        [byte[]]$byteArray = New-Object byte[] $byteCount

        # Loop through the hex string in pairs of characters
        for ($i = 0; $i -lt $byteCount; $i++) {
            # Extract a pair of characters
            $hexPair = $HexString.Substring($i * 2, 2)

            # Convert the hex pair to a byte and assign it to the array
            $byteArray[$i] = [Convert]::ToByte($hexPair, 16)
        }

        # Output the byte array
        return [OctetStringValue]::new($byteArray)

    }
}


<#
.SYNOPSIS
    Represents a string
#>
class StringValue : MetasysValue {
    hidden [string] $_value

    hidden static $ValueDefinition = @{
        TypeName   = 'StringValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._value
        }
    }

    StringValue([string]$value) {
        $this._value = $value;
        $Definition = [StringValue]::ValueDefinition
        Update-TypeData @Definition
    }

    [string] ToString() {
        return $this._value
    }
}


class BitStringValue : MetasysValue {
    hidden [string] $_value

    hidden static $ValueDefinition = @{
        TypeName   = 'BitStringValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._value
        }
    }

    BitStringValue([bool[]]$bits) {
        $stringValue = $bits | ForEach-Object { if ($_) { "1" } else { "0" } }
        $this.Initialize($stringValue)
    }

    hidden BitStringValue([string]$value) {
        $this.Initialize($value)
    }

    static [BitStringValue] Parse([string]$value) {
        $value.ToCharArray() | ForEach-Object {
            if ($_ -notin "0", "1") {
                throw "$_ is an illegal character in a BitString"
            }
        }
        return [BitStringValue]::new($value)
    }

    hidden [void]Initialize([string]$value) {
        $this._value = $value;
        $Definition = [BitStringValue]::ValueDefinition
        Update-TypeData @Definition
    }

    [string] ToString() {
        return $this._value
    }

    [bool[]] ToBools() {
        return $this._value.ToCharArray() | ForEach-Object { if ($_ -eq "1") { $true } else { $false } }
    }
}


<#
.SYNOPSIS
    Represents an enumerated value
#>
class EnumValue : MetasysValue {
    hidden [string] $_set
    hidden [string] $_member

    hidden static $ValueDefinition = @{
        TypeName   = 'EnumValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return "$($this._set).$($this._member)"
        }
    }

    hidden static $SetDefinition = @{
        TypeName   = 'EnumValue'
        MemberName = 'Set'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._set
        }
    }

    hidden static $MemberDefinition = @{
        TypeName   = 'EnumValue'
        MemberName = 'Member'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._member
        }
    }

    EnumValue([string]$set, [string]$member) {
        $this._set = $set
        $this._member = $member
        $VDefinition = [EnumValue]::ValueDefinition
        $SDefinition = [EnumValue]::SetDefinition
        $MDefinition = [EnumValue]::MemberDefinition
        Update-TypeData @VDefinition
        Update-TypeData @SDefinition
        Update-TypeData @MDefinition
    }

    static [EnumValue] Parse([string]$value) {
        $parts = $value.Split(".")
        if ($parts.Count -ne 2) {
            throw "Invalid enum value"
        }
        return [EnumValue]::new($parts[0], $parts[1])
    }


    [string] ToString() {
        return $this.Value
    }
}

class EnumMemberIdValue : MetasysValue {
    hidden [uint] $_value

    hidden static $ValueDefinition = @{
        TypeName   = 'EnumMemberIdValue'
        MemberName = 'Value'
        MemberType = 'ScriptProperty'
        Value      = {
            return $this._value
        }
    }

    EnumMemberIdValue([uint]$value) {
        $this._value = $value;
        $Definition = [EnumMemberIdValue]::ValueDefinition
        Update-TypeData @Definition
    }

    [string] ToString() {
        return $this._value.ToString()
    }
}
