# Invoke Metays Method README

> **Note:** This is *alpha* quality software. I appreciate your feedback and/or pull requests. Let me know what other features should be added.

## Usage

```powershell
> ./Invoke-MetasysMethod.ps1 [[-Method] <string>] [[-Site] <string>]
>   [[-Version] <Int32>] [[-Path] <string>][[-Body] <string>] [[]] [[-UserName] <string>]
>   [[-Reference] <string>] [-Clear] [-SkipCertificateCheck]
```



## Read an Object

This can be done in 2 steps. The first is to get the guid of the object and the second is to read the object.

```powershell
> $id = ./Invoke-MetasysMethod.ps1 -Reference thesun:thesun

Site: thesun.cg.na.jci.com
UserName: Michael
Password: **********
```

Notice that it prompted me for the site and my credentials. Next I'll read the object

```powershell
> $object = ./Invoke-MetasysMethod.ps1 -Path /objects/$id

```

And that's it! Notice I didn't have to enter in the site information or my credentials. All of this is cached in the terminal session. (The token is securely cached).

You can examine the object like any powershell object:

```powershell
> $object.item.name

thesun
> $object.item.description

```

## Read an Attribute

Now we'll read just one attribute - the status - of the site object

```powershell
 > $siteObject = ./Invoke-MetasysMethod.ps1 -Path /objects/$id/attributes/status

> $siteObject.item


status
------
objectStatusEnumSet.osNormal
```

## Write the Description

Now we'll write the description to be "The Sun Server"

```powershell
> $json = '{ "item": { "description": "The Sun Server" } }'

> ./Invoke-MetasysMethod.ps1 -Method Patch -Body $json -Path /objects/$id
```

And we'll read it back to see it changed

```powershell
> $description = ./Invoke-MetasysMethod.ps1 -Path /objects/$id/attributes/description

> $description.item.description

The Sun Server
```

## List Commands

Now let's take a look at some commands on an AV:

```powershell
> ./Invoke-MetasysMethod.ps1 -Reference thesun:TSunN50/AV1

ec73dbb1-db01-5e59-aaff-6552288bba54
```

And we'll use that to look up commands

```powershell
> $commands = > ./Invoke-MetasysMethod.ps1 -Path /objects/ec73dbb1-db01-5e59-aaff-6552288bba54/commands
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

I need to construct the payload which is easy. It's just `[55.0]` where `55` is the value I want to send. Commands always take an array (even if it's empty).

```powershell
> $currentValue = ( ./Invoke-MetasysMethod.ps1 -Path /objects/7ecb7158-e2b5-52af-a4cf-b352486406fc/attributes/presentValue).item.presentValue

> $currentValue

0
```

Now send the command

```powershell
> 


## Explicitly Login

Normally you don't need to explicitly login. If you attempt to invoke a method the script will prompt you for which a site as well as your credentials. But if at any time you want to switch sites or user accounts, you'll want to let the script know. Otherwise, it'll continue with the existing session.

### Use the Login Switch

Force a login with the `-Login` switch

Here you can see that I have a valid session as I'm able to read the id of an object

```powershell
> ./Invoke-MetasysMethod.ps1 -Reference thesun:thesun

c05d5d30-ebf0-5533-8e67-f74bb728bf18
```

Now I'll make the same call but with `-Login` switch

```powershell
> ./Invoke-MetasysMethod.ps1 -Reference thesun:thesun -Login

Site: thesun.cg.na.jci.com
UserName: Michael
Password: **********
c05d5d30-ebf0-5533-8e67-f74bb728bf18
```

### Use the Site Parameter

Now I'm going to make a call to a different site. I could just pass `-Login` but I want to go ahead and pass the site and my username on the command line:

```powershell
> ./Invoke-MetasysMethod.ps1 -Reference WIN-21DJ9JV9QH6:WIN-21DJ9JV9QH6 -Site 10.164.104.81 -UserName testuser

Password: ************
1949c631-7823-5230-b951-aae3f8c9d64a
```

You can see this time it only prompted me for my password.

### Clear Your Session

All of the session state is stored in environment variables. If at any time you just want to make sure all of the env variables are cleared out you can quit your terminal session or use the `-Clear` switch.

So I'll go ahead and use `-Clear`

```powershell
> ./Invoke-MetasysMethod.ps1 -Clear
```

And then make the same call as in the last section (without -Site or -UserName) and you'll see I'm prompted for credentials

```powershell
> ./Invoke-MetasysMethod.ps1 -Reference WIN-21DJ9JV9QH6:WIN-21DJ9JV9QH6

Site: 10.164.104.81
UserName: testuser
Password: ************
1949c631-7823-5230-b951-aae3f8c9d64a
```