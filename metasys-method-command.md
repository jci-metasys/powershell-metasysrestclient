# Invoke Metasys Method README

> **Note:** This is *alpha* quality software. I appreciate your feedback and/or pull requests. Let me know what other features should be added.

## Installation

```powershell
PS> Install-Module -Name Invoke-MetasysMethod
```

## Usage

```powershell
> Invoke-MetasysMethod [[-Method] <string>] [[-Site] <string>]
>   [[-Version] <Int32>] [[-Path] <string>][[-Body] <string>] [[]] [[-UserName] <string>]
>   [[-Reference] <string>] [-Clear] [-SkipCertificateCheck]
```

Some documentation is provided by the help system:

```powershell
> help Invoke-MetasysMethod
```

## Read an Object

This can be done in 2 steps. The first is to get the guid of the object and the second is to read the object. I'm using `-Reference thesun:thesun` switch which is just a short cut for calling `-Path /objectIdentifiers?fqr=thesun:thesun`. I find I'm often looking up object ids so this made it slightly easier.

```powershell
> $id = Invoke-MetasysMethod -Reference thesun:thesun

Site: thesun.cg.na.jci.com
UserName: Michael
Password: **********
```

Notice that it prompted me for the site and my credentials. Let's examine the id to make sure it worked:

```powershell
$id

c05d5d30-ebf0-5533-8e67-f74bb728bf18
```

That looks like a valid guid. Next I'll read the object

```powershell
> $object = Invoke-MetasysMethod -Path /objects/$id

```

And that's it! Notice I didn't have to enter in the site information or my credentials. All of this is cached in the terminal session. (The token is securely cached).

You can examine the object like any powershell object:

```powershell
> $object.item.name

thesun
> $object.item.description

```

In this case the description was empty so there was nothing to see.

Or you can see the whole `item` section (which contains all of the attributes) and convert it to json

```powershell
> ConvertTo-Json $object.item -Depth 10

{
  "attrChangeCount": 0.0,
  "name": "thesun",
  "description": "The Sun Server",
  "bacnetObjectType": "objectTypeEnumSet.adsClass",
  "objectCategory": "objectCategoryEnumSet.systemCategory",
  "version": {
    "major": 34,
    "minor": 0
  },
  "modelName": "ADS",
  "localTime": {
    "hour": 6,
    "minute": 16,
    "second": 45,
    "hundredth": 321
  },
  "localDate": {
    "year": 2020,
    "month": 6,
    "dayOfMonth": 29,
    "dayOfWeek": 1
  },
  "itemReference": "thesun:thesun",
  "fipsComplianceStatus": "noOfComplianceStateEnumSet.nonCompliantUnlicensed",
  "almSnoozeTime": 5.0,
  "auditEnabledClasLev": 2.0,
  "addAdsrepos": [],
  "adsRepositoriesStatus": [],
  "sampleRate": 139.2857,
  "serviceTime": 56.0,
  "numberOfNxesReporting": 8.0,
  "transferBufferFullWorstNxe": 4.0,
  "hostName": "Granymede4201",
  "isValidated": false,
  "id": "c05d5d30-ebf0-5533-8e67-f74bb728bf18"
}
```

## Environment Variables

There are a couple enviroment variables that are set that you might find useful.

Here I'm inspecting what site I'm on.

```powershell
> $env:METASYS_SITE

thesun.cg.na.jci.com
```

Let's say I made a call but forgot to store it in a variable. You can use `$env:METASYS_LAST_RESPONSE`

For example, let me fetch the object again:

```powershell
> Invoke-MetasysMethod -Path /objects/$id

self                 : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18?includeSchema=false&viewId=viewNameEnumSet.focusView
objectType           : objectTypeEnumSet.adsClass
parentUrl            : https://thesun.cg.na.jci.com/api/v3/objects/8e16a75e-20e8-55bd-ac11-926c1122d69c
objectsUrl           : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/objects
networkDeviceUrl     :
pointsUrl            : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/points
trendedAttributesUrl : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/trendedAttributes
alarmsUrl            : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/alarms
auditsUrl            : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/audits
item                 : @{attrChangeCount=0; name=thesun; description=The Sun Server; bacnetObjectType=objectTypeEnumSet.adsClass; objectCategory=objectCategoryEnumSet.systemCategory; version=; modelName=ADS; localTime=; localDate=; itemReference=thesun:thesun;
                       fipsComplianceStatus=noOfComplianceStateEnumSet.nonCompliantUnlicensed; almSnoozeTime=5; auditEnabledClasLev=2; addAdsrepos=System.Object[]; adsRepositoriesStatus=System.Object[]; sampleRate=0; serviceTime=56; numberOfNxesReporting=8; transferBufferFullWorstNxe=4; hostName=Granymede4201;
                       isValidated=False; id=c05d5d30-ebf0-5533-8e67-f74bb728bf18}
views                : {@{title=Focus; views=System.Object[]; id=viewNameEnumSet.focusView}}
condition            :
```

But I wanted it to be in a variable so that I could query it like a normal object rather than copy paste. Or in this case I can't see all of the `item` section because the default rendering doesn't show everything. Not to worry. The full json representation is in the environment variable

```powershell
$env:METASYS_LAST_RESPONSE

{
  "self": "https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18?includeSchema=false&viewId=viewNameEnumSet.focusView",
  "objectType": "objectTypeEnumSet.adsClass",
  "parentUrl": "https://thesun.cg.na.jci.com/api/v3/objects/8e16a75e-20e8-55bd-ac11-926c1122d69c",
  "objectsUrl": "https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/objects",
  "networkDeviceUrl": null,
  "pointsUrl": "https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/points",
  "trendedAttributesUrl": "https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/trendedAttributes",
  "alarmsUrl": "https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/alarms",
  "auditsUrl": "https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18/audits",
  "item": {
    "attrChangeCount": 0.0,
    "name": "thesun",
    "description": "The Sun Server",
    "bacnetObjectType": "objectTypeEnumSet.adsClass",
    "objectCategory": "objectCategoryEnumSet.systemCategory",
    "version": {
      "major": 34,
      "minor": 0
...truncated
```

If I want to store this for later in my own object (rather than JSON):

```powershell
> $object = ConvertFrom-Json $env:METASYS_LAST_RESPONSE

> $object.item.name

thesun
```

## Read an Attribute

Now we'll read just one attribute - the status - of the site object

```powershell
 > $siteObject = Invoke-MetasysMethod -Path /objects/$id/attributes/status

> $siteObject.item


status
------
objectStatusEnumSet.osNormal
```

## Write the Description

Now we'll write the description to be "The Sun Server"

```powershell
> $json = '{ "item": { "description": "The Sun Server" } }'

> Invoke-MetasysMethod -Method Patch -Body $json -Path /objects/$id
```

And we'll read it back to see it changed

```powershell
> $description = Invoke-MetasysMethod -Path /objects/$id/attributes/description

> $description.item.description

The Sun Server
```

## List Commands

Now let's take a look at some commands on an AV:

```powershell
> Invoke-MetasysMethod -Reference thesun:TSunN50/AV1

ec73dbb1-db01-5e59-aaff-6552288bba54
```

And we'll use that to look up commands

```powershell
> $commands = > Invoke-MetasysMethod -Path /objects/ec73dbb1-db01-5e59-aaff-6552288bba54/commands
```

Now let's take a look at the commands. I'm just going to look at the first one which I know is `adjust`

```powershell
> $commands.items[0]


$schema   : http://json-schema.org/schema#
commandId : adjust
title     : Adjust
type      : array
items     : {@{type=number; title=Value; minimum=; maximum=}}
minItems  : 1
maxItems  : 1
```

The payload is a JSON schema. It tells me the `commandId` which is `adjust`. This is what I'll use in the URL to send the command. The `items` gives me the schemas for the parameters. But I can't see all the details. So I'm going to print them out.

```powershell
> $commands.items[0].items


type   title minimum maximum
----   ----- ------- -------
number Value
```

Now I can see that their is one parameter of type `number`. In the next section I'll send the command.

## Send Command

I need to construct the payload which is easy. It's just `[72.34]` where `72.34` is the value I want to send. Commands always take an array (even if it's empty).

```powershell
> $response = Invoke-MetasysMethod -Path /objects/7ecb7158-e2b5-52af-a4cf-b352486406fc/attributes/presentValue

> $response.item.presentValue

0
```

Now send the command

```powershell
> Invoke-MetasysMethod -Method Put -Path /objects/7ecb7158-e2b5-52af-a4cf-b352486406fc/commands/adjust -Body '[72.34]'

```

And read the value back

```powershell
> $response = Invoke-MetasysMethod -Path /objects/7ecb7158-e2b5-52af-a4cf-b352486406fc/attributes/presentValue

> $response.item.presentValue

72.34
```

## Explicitly Login

Normally you don't need to explicitly login. If you attempt to invoke a method the script will prompt you for which a site as well as your credentials. But if at any time you want to switch sites or user accounts, you'll want to let the script know. Otherwise, it'll continue with the existing session.

### Use the Login Switch

Force a login with the `-Login` switch

Here you can see that I have a valid session as I'm able to read the id of an object

```powershell
> Invoke-MetasysMethod -Reference thesun:thesun

c05d5d30-ebf0-5533-8e67-f74bb728bf18
```

Now I'll make the same call but with `-Login` switch

```powershell
> Invoke-MetasysMethod -Reference thesun:thesun -Login

Site: thesun.cg.na.jci.com
UserName: Michael
Password: **********
c05d5d30-ebf0-5533-8e67-f74bb728bf18
```

### Use the Site Parameter

Now I'm going to make a call to a different site. I could just pass `-Login` but I want to go ahead and pass the site and my username on the command line:

```powershell
> Invoke-MetasysMethod -Reference WIN-21DJ9JV9QH6:WIN-21DJ9JV9QH6 -Site 10.164.104.81 -UserName testuser

Password: ************
1949c631-7823-5230-b951-aae3f8c9d64a
```

You can see this time it only prompted me for my password.

### Clear Your Session

All of the session state is stored in environment variables. If at any time you just want to make sure all of the env variables are cleared out you can quit your terminal session or use the `-Clear` switch.

So I'll go ahead and use `-Clear`

```powershell
> Invoke-MetasysMethod -Clear
```

And then make the same call as in the last section (without -Site or -UserName) and you'll see I'm prompted for credentials

```powershell
> Invoke-MetasysMethod -Reference WIN-21DJ9JV9QH6:WIN-21DJ9JV9QH6

Site: 10.164.104.81
UserName: testuser
Password: ************
1949c631-7823-5230-b951-aae3f8c9d64a
```