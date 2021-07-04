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
