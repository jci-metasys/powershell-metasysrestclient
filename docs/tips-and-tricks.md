#### Multiline String Literals

 The first way to do it is to take advantage of multiline string literals in powershell.

```bash
> Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba -Method Patch -Body @"
>> {
>>   "item": {
>>     "description": "Zone 3 Temperature Setpoint"
>>   }
>> }
>> "@
```

A multiline string literal begins with `@"` and ends with `"@` and they must be on their own line like shown. After typing `@"` and hitting return, powershell displays the `>>` prompt letting us know that it expects more input. (You don't type the `>>` characters they will already be displayed.)

#### Using the Contents of File

We can also just create the content in a file using our favorite text editor. Assume the contents of the file are named `write-description.json`. Then we can do this:

```bash
> Get-Content ./write-description.json -Raw | Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba -Method Patch
```

In this example, we use `Get-Content` to read our file and then we pipe it to `Invoke-MetasysMethod`. Note, we didn't need to specify the `Body` parameter in this case because it's the only parameter that can take piped input.

An alternative way to write this without piping would be

```bash
> Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba -Method Patch -Body (Get-Content -Raw ./write-description.json)
```

> **Note:** Be sure to use the `Raw` switch with `Get-Content` so that the contents of the file are returned as a single string, rather than as an array of strings.

#### Using Variables

Either of the preceding examples could have made use of a variable to store the contents of the file. This can be useful if you plan to send the same contents multiple times.

##### Using Variable to hold Multiline String

In this example we type a multiline string literal and save it to a variable so it can be used multiple times.

```bash
> $writeBody =  @"
>> {
>>   "item": {
>>     "description": "Zone 3 Temperature Setpoint"
>>   }
>> }
>> "@
> Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba -Method Patch -Body $writeBody
```

##### Using Variable to hold Contents of File

```bash
> $writeBody = Get-Content -Raw ./write-description.json
> Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba -Method Patch -Body $writeBody
```

##### Using Hashtables To Create JSON

Another trick for longer examples is to use Hashtables and convert them to JSON.

```bash
> $writeBody.item = @{}
> $writeBody.item.description = "Zone 3 Temperature Setpoint"
> $writeBody | ConvertTo-Json
{
  "item": {
    "description": "Zone 3 Temperature Setpoint"
  }
}
```

## Credential Management

* Microsoft.PowerShell.SecretManagement (if you wish for your credentials to be securely saved)
* A Secret Vault of your choice
  * Microsoft.PowerShell.SecretStore (recommended, cross-platform)
  *


### Using PowerShell to find an Object

In these examples, I'll show some simple scripts to work the the results to find an object. This is handy when I want to create a new object and I need to know the id of a location where I can create.

#### Using Select-Object To Filter The Results

JSON Responses can be rather lengthy. In this example I demonstrate how to use the properties on the response along with `Select-Object` just to see what I want.

```bash
PS /Users/cwelchmi> (Invoke-MetasysMethod /objects -ReturnBodyAsObject).items[0].items | Select-Object name, objectType, self

name                objectType                       self
----                ----------                       ----
User Views          objectTypeEnumSet.containerClass https://welchoas/api/v4/objects/c8dd833e-427b-55a1-9f7d-c4f09ea3524d
Summary Definitions objectTypeEnumSet.containerClass https://welchoas/api/v4/objects/7fd71bf8-c080-59c3-835f-e5c5f0ffabbb
welchoas            objectTypeEnumSet.oasClass       https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b
```

Let's break it down. The call to `/objects` returns a tree. At the root of the tree is the site director (because I am logged into a site director). Therefore I know that `items` has only one entry. I select it with the `.items[0]`. That object (the site director) also has an `items` property which is all of it's direct descendants. I select them with the `.items`. Putting it all together I get `(Invoke-MetasysMethod /objects -ReturnBodyAsObject).items[0].items`. This returns a collection which I pipe to `Select-Object` which allows me to just select the properties of each entry in the collection that I want.



### Clearing Credentials

Once you've authenticated against a site, your credentials are securely stored in your operating systems keychain. If your credentials ever change, you'll want to remove the saved credentials from the keychain. You can do this with the `DeleteCredentials` parameter. For example, if your credentials for the host named `adx32` have changed you'd run this command to delete them.

```bash
> Invoke-MetasysMethod -DeleteCredentials adx32
```
