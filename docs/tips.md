# Tips for Working With PowerShell

* Creating JSON Strings
* Working with Response Objects
* Saving Data to Variables
  * Using -OutVariable
  * Pipe to Set-Variable
  * Or just remember to type ${var} = first

## Creating JSON Strings

If you want to send any requests that change the state of Metasys you most likely will need to work with JSON. Issuing commands with long JSON strings can be difficult or error prone. In this section we'll examine different ways of creating JSON strings.

### Normal String Literal

The simplest approach to dealing with JSON is to just type it all out in a normal string. PowerShell allows you to write strings within single quotes or double quotes. We'll take advantage of this. We'll use single quotes in the following example, which allows us to use double quotes like we normally would for JSON property identifiers:

```bash
PS > Invoke-MetasysMethod /objects/$Id -Method Patch -Body '{ "item": { "description": "Test Object" } }'
```

This typically works well enough if the string is short or you can easily copy/paste it from somewhere else.

> **Note:** This only works if the string you are pasting doesn't have line breaks in it. See the next section if you are copying JSON with line breaks.

If you'll be using this string several times, save it in a variable first. For example let's assume we are changing the `minPresValue` on a collection of `AV` objects.

```bash
PS > $minPresValueUpdate = '{ "item": { "minPresValue": 25.5 } }'
PS > Invoke-MetasysMethod /objects/$Id1 -Method Patch -Body $minPresValueUpdate
```

### Multiline String Literal

The next approach we'll use is multiline string literals. This approach works better than the previous approach since most JSON files are multiline. If you tried to paste one in to a normal string you'd immediately get an error at the first line break.

A multiline string literal begins with `@"` and ends with `"@` and they must be on their own line like shown. After typing `@"` and hitting return, powershell displays the `>>` prompt letting us know that it expects more input. (You don't type the `>>` characters they will already be displayed.)

```bash
PS > Invoke-MetasysMethod /objects/$Id -Method Patch -Body @"
>> {
>>   "item": {
>>     "description": "Zone 3 Temperature Set Point"
>>   }
>> }
>> "@
```

Again, this works pretty well if you are copying and pasting from somewhere. It also works pretty well when you are just typing. Even if you have a typo, you can use your shell history to edit the previous attempt and try again.

Like the previous example, if this is a payload you'll want to reuse store it in a variable first.

```bash
PS > $descriptionUpdate = @"
>> {
>>   "item": {
>>     "description": "Zone 3 Temperature Set Point"
>>   }
>> }
>> "@
PS > Invoke-MetsysMethod /objects/$Id -Method Patch -Body $descriptionUpdate
```

### Using a Hashtable

PowerShell supports Hashtable literals. A hashtable is defined beginning with `@{` and closing with `}` with key/value pairs defined in between.

If you were writing a script to do this you might build up the `$update` object all at once like this:

```powershell
$update = @{
  item = @{
    name = "ZN3-Setpt";
    description = "Temperature Set Point";
    connectedTo = @{
      objectReference = "welchoas:welchoas/AV2";
      attribute = "attributeEnumSet.presentValue"
    }
  }
}
```

Notice that we are using nested hashtables. Each object in JSON is it's own hashtable.

If you are writing this on the command line you could do the same thing or you could choose to build up the `$update` object one piece at a time like so:

```powershell
# Create the update object, with an item property with is also a hashtable
PS > $update = @{ item = @{ } }

# Set the name property value
PS > $update.item.name = "ZN3-Setpt"

# Set the description property value
PS > $update.item.description = "Temperature Set Point"

# Use a nested hashtable to define conectedTo
# Notice the prompt is >> as PowerShell is waiting for more input
PS > $update.item.connectedTo = @{
>> objectReference = "welchoas:welchoas/AV2";
>> attribute = "attributeEnumSet.presentValue"
>> }
```

I can then convert the `$update` object to JSON and use it in a `PATCH` request:

```bash
PS > $updateJSON = ConvertTo-JSON -Depth 20 $update
PS > Write-Output $updateJSON
{
  "item": {
    "description": "Temperature Setpoint",
    "name": "ZN3-Setpt",
    "connectedTo": {
      "objectReference": "welchoas:welchoas/AV2",
      "attribute": "attributeEnumSet.presentValue"
    }
  }
}
PS > imm /objects/$Id -Method Path -Body $updateJSON
```

### Using the Contents of File

We can also just create the content in a file using our favorite text editor. Assume the contents of the file are named `write-description.json`. Then we can do this:

```bash
> Get-Content ./write-description.json -Raw | Invoke-MetasysMethod /objects/$Id -Method Patch
```

In this example, we use `Get-Content` to read our file and then we pipe it to `Invoke-MetasysMethod`. Note, we didn't need to specify the `Body` parameter in this case because it's the only parameter that can take piped input.

An alternative way to write this without piping would be

```bash
> Invoke-MetasysMethod /objects/$Id -Method Patch -Body (Get-Content -Raw ./write-description.json)
```

> **Note:** Be sure to use the `Raw` switch with `Get-Content` so that the contents of the file are returned as a single string, rather than as an array of strings.

## Working With Response Objects

By default `Invoke-MetasysMethod` returns the content it receives from Metasys as a string. But since all responses are JSON we can convert them in to dynamic objects in PowerShell. To get this behavior automatically use the `ReturnBodyAsObject` switch.

```powershell
PS > imm /enumerations/onOffSet -ReturnBodyAsObject

self
----
https://welchoas/api/v4/enumerations/onOffSet?includeSchema=false&includePermi…
```

Let's save the result to a variable and interrogate it using it's properties.

```powershell
PS > $onOffSet = imm /enumerations/onOffSet -ReturnBodyAsObject

# Check the self property
PS > $onOffSet.self
https://welchoas/api/v4/enumerations/onOffSet?includeSchema=false&includePermissions=false

# Check the item property
PS > $onOffSet.item

name   members
----   -------
On/Off @{onOffSet.onoffOn=; onOffSet.onoffOff=}

# Let's look at the name and the on member
PS > $onOffSet.item.name
On/Off

PS > $onOffSet.item.members.onOffSet
$onOffSet.item.members.'onOffSet.onoffOn'

value name
----- ----
    0 On
```

### Using PowerShell to find an Object

In these examples, I'll show some simple scripts to work with the results to find an object. This is handy when I want to create a new object and I need to know the id of a location where I can create.

#### Using Select-Object To Filter The Results

JSON Responses can be rather lengthy. In this example I demonstrate how to use the properties on the response along with `Select-Object` just to see what I want.

```bash
PS /Users/cwelchmi> imm /objects?flatten=true -ReturnBodyAsObject | Select-Object -ExpandProperty items  | Select-Object name, objectType, self


name                objectType                       self
----                ----------                       ----
Site                objectTypeEnumSet.siteClass      https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962
User Views          objectTypeEnumSet.containerClass https://welchoas/api/v4/objects/c8dd833e-427b-55a1-9f7d-c4f09ea3524d
Summary Definitions objectTypeEnumSet.containerClass https://welchoas/api/v4/objects/7fd71bf8-c080-59c3-835f-e5c5f0ffabbb
welchoas            objectTypeEnumSet.oasClass       https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b
```

Let's break it down. The call to `/objects?flatten=true` returns a list inside of an `items` property. So I pipe the output of my request to `Select-Object` and tell it to expand the property named `items`. This returns a collection of all of the attributes. Then I pipe that to `Select-Object` and tell it precisely which properties of each attribute I want. In this case the `name`, `objectType` and `self`.

#### Using ForEach-Object To Find Spaces with Equipment

In this next example I'm going to write a one-liner that checks the `equipmentUrl` for each space to see which have any equipment defined.

```powershell
PS > imm -SiteHost diana12oas /spaces -ReturnBodyAsObject | Select-Object -ExpandProperty items | ForEach-Object { imm $_.equipmentUrl -ReturnBodyAsObject } | Where-Object { $_.total -gt 0 }
```

<details><summary>Click to see the response</summary>

```powershell

total    : 1
next     :
previous :
items    : {@{id=e1446605-6d11-58d1-bca8-8a3c6663dc03; itemReference=diana12oas:diana12oas/equipment.diana12oas.Test Objects; name=Equip1; type=Equipment Definition1; self=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03; spacesUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/spaces; equipmentUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/equipment; upstreamEquipmentUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/upstreamEquipment; networkDevicesUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/networkDevices; pointsUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/points}}
self     : https://diana12oas/api/v4/spaces/35856bf6-fd36-51da-96b8-7ac643000d81/equipment?pageSize=100&page=1&sort=name

total    : 2
next     :
previous :
items    : {@{id=e1446605-6d11-58d1-bca8-8a3c6663dc03; itemReference=diana12oas:diana12oas/equipment.diana12oas.Test Objects; name=Equip1; type=Equipment Definition1; self=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03; spacesUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/spaces; equipmentUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/equipment; upstreamEquipmentUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/upstreamEquipment; networkDevicesUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/networkDevices; pointsUrl=https://diana12oas/api/v4/equipment/e1446605-6d11-58d1-bca8-8a3c6663dc03/points}, @{id=8e20752f-7239-5870-a5ef-54bf22d63160; itemReference=diana12oas:diana12oas/equipment.diana12oas.AuthZ; name=Equip2; type=Equipment Definition1; self=https://diana12oas/api/v4/equipment/8e20752f-7239-5870-a5ef-54bf22d63160; spacesUrl=https://diana12oas/api/v4/equipment/8e20752f-7239-5870-a5ef-54bf22d63160/spaces; equipmentUrl=https://diana12oas/api/v4/equipment/8e20752f-7239-5870-a5ef-54bf22d63160/equipment; upstreamEquipmentUrl=https://diana12oas/api/v4/equipment/8e20752f-7239-5870-a5ef-54bf22d63160/upstreamEquipment; networkDevicesUrl=https://diana12oas/api/v4/equipment/8e20752f-7239-5870-a5ef-54bf22d63160/networkDevices; pointsUrl=https://diana12oas/api/v4/equipment/8e20752f-7239-5870-a5ef-54bf22d63160/points}}
self     : https://diana12oas/api/v4/spaces/7047f4b8-6740-5585-a2a5-b10e13630788/equipment?pageSize=100&page=1&sort=name

total    : 1
next     :
previous :
items    : {@{id=d40e96c6-d474-5aaf-be85-cfcbabb30334; itemReference=diana12oas:diana12oas/equipment.DSJN50.FolderPoints; name=Equip3; type=Equipment Definition1; self=https://diana12oas/api/v4/equipment/d40e96c6-d474-5aaf-be85-cfcbabb30334; spacesUrl=https://diana12oas/api/v4/equipment/d40e96c6-d474-5aaf-be85-cfcbabb30334/spaces; equipmentUrl=https://diana12oas/api/v4/equipment/d40e96c6-d474-5aaf-be85-cfcbabb30334/equipment; upstreamEquipmentUrl=https://diana12oas/api/v4/equipment/d40e96c6-d474-5aaf-be85-cfcbabb30334/upstreamEquipment; networkDevicesUrl=https://diana12oas/api/v4/equipment/d40e96c6-d474-5aaf-be85-cfcbabb30334/networkDevices; pointsUrl=https://diana12oas/api/v4/equipment/d40e96c6-d474-5aaf-be85-cfcbabb30334/points}}
self     : https://diana12oas/api/v4/spaces/d4c025db-db0e-56dc-910b-aa1d7bdbd723/equipment?pageSize=100&page=1&sort=name


```

</details>

Now let's break it down step by step.

The first command just fetches the first page of spaces and returns the response as an object:

```powershell
imm -SiteHost diana12oas /spaces -ReturnBodyAsObject
```

Like in the previous example, we pipe result to `Select-Object` and expand the `items` property

```powershell
# Expand the items property of the previous command
... | Select-Object -ExpandProperty items
```

Everty space has a `equipmentUrl` so we use that to fetch the equipment for each space. We do this by piping the last result to `For-EachObject`. `For-EachObject` takes a closure which allows you to take some action on each item in a collection. The variable `$_` is used to access the item

```powershell
# Fetch the equipmentUrl for each object and return the response as an object
... | ForEach-Object { imm $_.equipmentUrl -ReturnBodyAsObject }
```

Finally we pipe the results to `Where-Object` where we can filter the results to just those that have more than 0 equipment.

```powershell
# Filter down the list to just include those that have a total greater than 0
... | | Where-Object { $_.total -gt 0 }
```
