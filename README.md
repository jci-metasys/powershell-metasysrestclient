# Invoke-MetasysMethod

A light weight wrapper around the powershell `Invoke-WebRequest` command.

Features:

* Securely stores credentials in OS keychain after your first successful login to a Metasys device
* Establishes a "session" with a Metasys device so you don't need to send credentials on each call
* Manages the access token for you so you don't need to explicitly send it on each request
* Provides some helper cmdlets to inspect all the results of the previous command

## Dependencies

Powershell Core for your OS: See the [repository](https://github.com/powershell/powershell).

## Prerequisites

This guide assumes you have some familiarity with REST APIs in general and the Metasys REST API specifically.

See the Documentation for the Metasys REST API for more information on what endpoints are available and what their payloads look like.

## Metasys REST API Versions

Examples in this README are from `v4` of the API. However, `Invoke-MetasysMethod` works with `v2` and `v3` as well, but you'll need to explicitly include the `-Version` parameter when making calls. Else `Invoke-MetasysMethod` assumes `v4`.

## Install

From a powershell shell:

```bash
PS > Install-Module Invoke-MetasysMethod

Untrusted repository
You are installing the modules from an untrusted repository. If you trust this
repository, change its InstallationPolicy value by running the Set-PSRepository
 cmdlet. Are you sure you want to install the modules from 'PSGallery'?
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help
(default is "N"):Y
```

## Help

You can type

```bash
> help Invoke-MetasysMethod
```

To see the list of parameters that are supported.

## How To Use

This section will show you the basics of using `Invoke-MetasysMethod`

### Starting a Session

To get started you need to get logged into a site.

To do this, simply call `Invoke-MetasysMethod` with no parameters. You'll be prompted for your `Site host`, `username` and `password`. Your credentials which will be securely stored in your OS keychain. After that you'll never need to enter your credentials for that site again. (If your credentials change, you'll want to clear them from your keychain. See [Clearing Credentials from your Keychain]() )

```bash
PS > Invoke-MetasysMethod

Site host: welchoas
UserName: api
Password: *********
```

> **Note** You don't need to explicitly do this login step separately. It's safe to call `Invoke-MetasysMethod` with a request and if you haven't already established a session, you'll be prompted for your credentials.

### Reading Information (GET)

When you want to read information from Metasys you'll normally be doing a `GET` request. These are the easiest to work with because they only require a URL and nothing else. You can use a relative or absolute url.


```bash
PS > Invoke-MetasysMethod /objects

Site host: welchoas
UserName: api
Password: *********
```

The result of this command will return the root of the objects collection and it's direct descendants:

<!-- markdownlint-disable no-inline-html -->

<details><summary>Click to see the response</summary>

```json
{
  "self": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962/objects?flatten=false&includeExtensions=true&includeInternal=false&depth=1",
  "items": [
    {
      "self": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962",
      "parentUrl": null,
      "networkDeviceUrl": null,
      "pointsUrl": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962/points",
      "objectsUrl": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962/objects",
      "alarmsUrl": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962/alarms",
      "auditsUrl": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962/audits",
      "trendedAttributesUrl": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962/trendedAttributes",
      "itemReference": "welchoas:welchoas/$site",
      "hasChildrenMatchingQuery": true,
      "name": "Site",
      "id": "896f7c45-de4b-5a2c-9084-bceb0ec85962",
      "objectType": "objectTypeEnumSet.siteClass",
      "classification": "site",
      "items": [
        {
          "self": "https://welchoas/api/v4/objects/c8dd833e-427b-55a1-9f7d-c4f09ea3524d",
          "parentUrl": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962",
          "networkDeviceUrl": "https://welchoas/api/v4/networkDevices/896f7c45-de4b-5a2c-9084-bceb0ec85962",
          "pointsUrl": "https://welchoas/api/v4/objects/c8dd833e-427b-55a1-9f7d-c4f09ea3524d/points",
          "objectsUrl": "https://welchoas/api/v4/objects/c8dd833e-427b-55a1-9f7d-c4f09ea3524d/objects",
          "alarmsUrl": "https://welchoas/api/v4/objects/c8dd833e-427b-55a1-9f7d-c4f09ea3524d/alarms",
          "auditsUrl": "https://welchoas/api/v4/objects/c8dd833e-427b-55a1-9f7d-c4f09ea3524d/audits",
          "trendedAttributesUrl": "https://welchoas/api/v4/objects/c8dd833e-427b-55a1-9f7d-c4f09ea3524d/trendedAttributes",
          "itemReference": "welchoas:welchoas/$site.UserTrees",
          "hasChildrenMatchingQuery": false,
          "name": "User Views",
          "id": "c8dd833e-427b-55a1-9f7d-c4f09ea3524d",
          "objectType": "objectTypeEnumSet.containerClass",
          "classification": "folder",
          "items": []
        },
        {
          "self": "https://welchoas/api/v4/objects/7fd71bf8-c080-59c3-835f-e5c5f0ffabbb",
          "parentUrl": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962",
          "networkDeviceUrl": "https://welchoas/api/v4/networkDevices/896f7c45-de4b-5a2c-9084-bceb0ec85962",
          "pointsUrl": "https://welchoas/api/v4/objects/7fd71bf8-c080-59c3-835f-e5c5f0ffabbb/points",
          "objectsUrl": "https://welchoas/api/v4/objects/7fd71bf8-c080-59c3-835f-e5c5f0ffabbb/objects",
          "alarmsUrl": "https://welchoas/api/v4/objects/7fd71bf8-c080-59c3-835f-e5c5f0ffabbb/alarms",
          "auditsUrl": "https://welchoas/api/v4/objects/7fd71bf8-c080-59c3-835f-e5c5f0ffabbb/audits",
          "trendedAttributesUrl": "https://welchoas/api/v4/objects/7fd71bf8-c080-59c3-835f-e5c5f0ffabbb/trendedAttributes",
          "itemReference": "welchoas:welchoas/$site.SummaryDefs",
          "hasChildrenMatchingQuery": false,
          "name": "Summary Definitions",
          "id": "7fd71bf8-c080-59c3-835f-e5c5f0ffabbb",
          "objectType": "objectTypeEnumSet.containerClass",
          "classification": "folder",
          "items": []
        },
        {
          "self": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b",
          "parentUrl": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962",
          "networkDeviceUrl": "https://welchoas/api/v4/networkDevices/896f7c45-de4b-5a2c-9084-bceb0ec85962",
          "pointsUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/points",
          "objectsUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/objects",
          "alarmsUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/alarms",
          "auditsUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/audits",
          "trendedAttributesUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/trendedAttributes",
          "itemReference": "welchoas:welchoas",
          "hasChildrenMatchingQuery": true,
          "name": "welchoas",
          "id": "8f2c6bb1-6bfd-5643-b581-299c1fec6b1b",
          "objectType": "objectTypeEnumSet.oasClass",
          "classification": "server",
          "items": []
        }
      ]
    }
  ],
  "effectivePermissions": {
    "canDelete": [
      "896f7c45-de4b-5a2c-9084-bceb0ec85962",
      "c8dd833e-427b-55a1-9f7d-c4f09ea3524d",
      "7fd71bf8-c080-59c3-835f-e5c5f0ffabbb"
    ],
    "canView": [
      "896f7c45-de4b-5a2c-9084-bceb0ec85962",
      "c8dd833e-427b-55a1-9f7d-c4f09ea3524d",
      "7fd71bf8-c080-59c3-835f-e5c5f0ffabbb",
      "8f2c6bb1-6bfd-5643-b581-299c1fec6b1b"
    ],
    "canModify": [
      "896f7c45-de4b-5a2c-9084-bceb0ec85962",
      "c8dd833e-427b-55a1-9f7d-c4f09ea3524d",
      "7fd71bf8-c080-59c3-835f-e5c5f0ffabbb",
      "8f2c6bb1-6bfd-5643-b581-299c1fec6b1b"
    ]
  }
}
```

</details>

An *absolute url* looks like `https://{hostname}/api/v4/objects`. Many API endpoints return absolute URLs in their response payloads. These are used to provide information about other useful resources on the system. So it's convenient to be able to copy and paste those to make another request.

A *relative url* looks like `/objects`. In other words, it's everything after `https://{hostname}/api/v4`.

In this next example we'll read the `presentValue` of an object. I happen to know the `id` for this object is `ce820989-5617-50bd-90ea-2fd95d1402ba`.

```bash
> Invoke-MetasysMethod https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/attributes/presentValue

{
  "item": {
    "presentValue": 68.2
  },
  "condition": {
    "presentValue": {}
  }
}
```

This time we showed the use of an absolute url. We could have just used `/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/attributes/presentValue` instead. Either type of url is fine.

Examples of other urls that support `GET`

* `/alarms` - Get first page of alarms
* `/audits` - Get first page of audits
* `/activities` - Get first page of the collection of all activities (the activities collection is a union of the alarms and audits collections)
* `/objects/$id/objects` - Get the child objects of the specified object where `$id` contains a valid object identifier.

### Writing An Object Attribute (PATCH)

In this example we'll change the value of an object attribute. This requires us to use two parameters `Method` to specify we are sending a `PATCH` request, and `Body` to specify the content we want to send to the server.

In this example we'll change the `description` attribute of an AV. Let's first read it to confirm it's currently `null`.

```bash
> Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba/attributes/description

{
  "item": {
    "description": null
    },
  "condition": {}
}
```

We'll change the value to be `Zone 3 Temperature Setpoint`. We are going to send this body to do that:

```json
{
  "item": {
    "description": "Zone 3 Temperature Setpoint"
  }
}
```

Assume this is saved in a file named `write-description.json` which is stored in the same director that we are currently executing `Invoke-MetasysMethod` from. Then we can do the following.

```bash
> Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba -Method Patch -Body (Get-Content -Raw ./write-description.json)
```

In this example, we used `Get-Content` to read our file

> **Note:** Be sure to use the `Raw` switch with `Get-Content` so that the contents of the file are returned as a single string, rather than as an array of strings.

It can be a little tricky dealing with large JSON strings. There's many ways to construct them. See [Tips and Tricks](docs/tips-and-tricks.md) for examples of working with JSON strings.

When your JSON string is short you can also just type it out as in this alternative:

```bash
> Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba -Method Patch -Body "{ 'item': { 'description': 'Zone 3 Temperature Setpoint' } }"
```

### Sending a Command to an Object (PUT)

In this example we'll send an `adjustCommand` command to an AV.

We can discover that the object supports `adjustCommand` by requesting the list of commands:

```bash
Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands
```

<details><summary> Click to see response</summary>

```json
{
  "self": "https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands",
  "items": [
    {
      "id": "commandIdEnumSet.adjustCommand",
      "invokeUrl": "https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands/commandIdEnumSet.adjustCommand",
      "title": "Adjust",
      "commandBodySchema": {
        "type": "object",
        "metasysType": "struct",
        "properties": {
          "priority": {
            "oneOf": [
              {
                "$ref": "#writePriorityEnumSet"
              },
              {
                "type": "null"
              }
            ]
          },
          "parameters": {
            "type": "array",
            "metasysType": "list",
            "items": [
              {
                "id": "commandParmsEnumSet.valueCmdparm",
                "title": "Value",
                "displayPrecisionSource": "displayPrecision",
                "maxPresValueSource": "maxPresValue",
                "minPresValueSource": "minPresValue",
                "unitsSource": "units",
                "metasysType": "float",
                "type": "number",
                "minimum": -1.69999997607218E+38,
                "maximum": 1.69999997607218E+38,
                "displayPrecision": {
                  "id": "displayPrecisionEnumSet.displayPrecisionPt1",
                  "displayMultipleOf": 0.1
                },
                "default": 0
              }
            ],
            "minItems": 1,
            "maxItems": 1
          },
          "annotation": {
            "title": "Annotation",
            "type": "string",
            "metasysType": "string",
            "minLength": 1,
            "maxLength": 255
          },
          "required": [],
          "additionalProperties": false
        },
        "definitions": {
          "writePriorityEnumSet": {
            "$schema": "http://json-schema.org/draft-07/schema#",
            "title": "Write Priority",
            "$id": "#writePriorityEnumSet",
            "allOf": [
              {
                "oneOf": [
                  {
                    "const": "writePriorityEnumSet.priorityNone",
                    "title": "0 (No Priority)",
                    "memberId": 0
                  },
                  {
                    "const": "writePriorityEnumSet.priorityManualEmergency",
                    "title": "1 (Manual Life Safety)",
                    "memberId": 1
                  },
                  {
                    "const": "writePriorityEnumSet.priorityFireApplications",
                    "title": "2 (Auto Life Safety)",
                    "memberId": 2
                  },
                  {
                    "const": "writePriorityEnumSet.priority3",
                    "title": "3 (Application)",
                    "memberId": 3
                  },
                  {
                    "const": "writePriorityEnumSet.priority4",
                    "title": "4 (Application)",
                    "memberId": 4
                  },
                  {
                    "const": "writePriorityEnumSet.priorityCriticalEquipment",
                    "title": "5 (Critical Equipment)",
                    "memberId": 5
                  },
                  {
                    "const": "writePriorityEnumSet.priorityMinimumOnOff",
                    "title": "6 (Minimum On Off)",
                    "memberId": 6
                  },
                  {
                    "const": "writePriorityEnumSet.priorityHeavyEquipDelay",
                    "title": "7 (Heavy Equip Delay)",
                    "memberId": 7
                  },
                  {
                    "const": "writePriorityEnumSet.priorityOperatorOverride",
                    "title": "8 (Operator Override)",
                    "memberId": 8
                  },
                  {
                    "const": "writePriorityEnumSet.priority9",
                    "title": "9 (Application)",
                    "memberId": 9
                  },
                  {
                    "const": "writePriorityEnumSet.priority10",
                    "title": "10 (Application)",
                    "memberId": 10
                  },
                  {
                    "const": "writePriorityEnumSet.priorityDemandLimiting",
                    "title": "11 (Demand Limiting)",
                    "memberId": 11
                  },
                  {
                    "const": "writePriorityEnumSet.priority12",
                    "title": "12 (Application)",
                    "memberId": 12
                  },
                  {
                    "const": "writePriorityEnumSet.priorityLoadRolling",
                    "title": "13 (Load Rolling)",
                    "memberId": 13
                  },
                  {
                    "const": "writePriorityEnumSet.priority14",
                    "title": "14 (Application)",
                    "memberId": 14
                  },
                  {
                    "const": "writePriorityEnumSet.prioritySchedulingOst",
                    "title": "15 (Scheduling)",
                    "memberId": 15
                  },
                  {
                    "const": "writePriorityEnumSet.priorityDefault",
                    "title": "16 (Default)",
                    "memberId": 16
                  }
                ]
              },
              {
                "$ref": "https://welchoas/api/v3/schemas/enums/writePriorityEnumSet"
              }
            ],
            "setId": 1
          }
        }
      }
    },
    {
      "id": "commandIdEnumSet.overrideCommand",
      "invokeUrl": "https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands/commandIdEnumSet.overrideCommand",
      "title": "Operator Override",
      "commandBodySchema": {
        "type": "object",
        "metasysType": "struct",
        "properties": {
          "parameters": {
            "type": "array",
            "metasysType": "list",
            "items": [
              {
                "id": "commandParmsEnumSet.valueCmdparm",
                "title": "Value",
                "displayPrecisionSource": "displayPrecision",
                "maxPresValueSource": "maxPresValue",
                "minPresValueSource": "minPresValue",
                "unitsSource": "units",
                "metasysType": "float",
                "type": "number",
                "minimum": -1.69999997607218E+38,
                "maximum": 1.69999997607218E+38,
                "displayPrecision": {
                  "id": "displayPrecisionEnumSet.displayPrecisionPt1",
                  "displayMultipleOf": 0.1
                },
                "default": 0
              }
            ],
            "minItems": 1,
            "maxItems": 1
          },
          "annotation": {
            "title": "Annotation",
            "type": "string",
            "metasysType": "string",
            "minLength": 1,
            "maxLength": 255
          },
          "required": [],
          "additionalProperties": false
        },
        "definitions": null
      }
    },
    {
      "id": "commandIdEnumSet.temporaryOverrideCommand",
      "invokeUrl": "https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands/commandIdEnumSet.temporaryOverrideCommand",
      "title": "Temporary Override",
      "commandBodySchema": {
        "type": "object",
        "metasysType": "struct",
        "properties": {
          "parameters": {
            "type": "array",
            "metasysType": "list",
            "items": [
              {
                "id": "commandParmsEnumSet.valueCmdparm",
                "title": "Value",
                "displayPrecisionSource": "displayPrecision",
                "maxPresValueSource": "maxPresValue",
                "minPresValueSource": "minPresValue",
                "unitsSource": "units",
                "metasysType": "float",
                "type": "number",
                "minimum": -1.69999997607218E+38,
                "maximum": 1.69999997607218E+38,
                "displayPrecision": {
                  "id": "displayPrecisionEnumSet.displayPrecisionPt1",
                  "displayMultipleOf": 0.1
                },
                "default": 0
              },
              {
                "id": "commandParmsEnumSet.hoursCmdparm",
                "title": "Hours",
                "metasysType": "ulong",
                "type": "integer",
                "minimum": 0,
                "maximum": 100,
                "default": 0
              },
              {
                "id": "commandParmsEnumSet.minutesCmdparm",
                "title": "Minutes",
                "metasysType": "ulong",
                "type": "integer",
                "minimum": 0,
                "maximum": 59,
                "default": 0
              }
            ],
            "minItems": 3,
            "maxItems": 3
          },
          "annotation": {
            "title": "Annotation",
            "type": "string",
            "metasysType": "string",
            "minLength": 1,
            "maxLength": 255
          },
          "required": [],
          "additionalProperties": false
        },
        "definitions": null
      }
    },
    {
      "id": "commandIdEnumSet.overrideReleaseCommand",
      "invokeUrl": "https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands/commandIdEnumSet.overrideReleaseCommand",
      "title": "Release Operator Override",
      "commandBodySchema": {
        "type": "object",
        "metasysType": "struct",
        "properties": {
          "annotation": {
            "title": "Annotation",
            "type": "string",
            "metasysType": "string",
            "minLength": 1,
            "maxLength": 255
          },
          "required": [],
          "additionalProperties": false
        },
        "definitions": null
      }
    },
    {
      "id": "commandIdEnumSet.releaseCommand",
      "invokeUrl": "https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands/commandIdEnumSet.releaseCommand",
      "title": "Release",
      "commandBodySchema": {
        "type": "object",
        "metasysType": "struct",
        "properties": {
          "parameters": {
            "type": "array",
            "metasysType": "list",
            "items": [
              {
                "id": "commandParmsEnumSet.attributeCmdparm",
                "title": "Attribute",
                "type": "string",
                "metasysType": "enum",
                "oneOf": [
                  {
                    "$ref": "#attributeEnumSet"
                  }
                ],
                "default": "attributeEnumSet.presentValue"
              },
              {
                "id": "commandParmsEnumSet.priorityCmdparm",
                "title": "Priority",
                "numberOfStates": 17,
                "type": "string",
                "metasysType": "enum",
                "oneOf": [
                  {
                    "$ref": "#writePriorityEnumSet_endAt_17"
                  }
                ],
                "default": "writePriorityEnumSet.priorityDefault"
              }
            ],
            "minItems": 2,
            "maxItems": 2
          },
          "annotation": {
            "title": "Annotation",
            "type": "string",
            "metasysType": "string",
            "minLength": 1,
            "maxLength": 255
          },
          "required": [],
          "additionalProperties": false
        },
        "definitions": {
          "attributeEnumSet": {
            "$schema": "http://json-schema.org/draft-07/schema#",
            "title": "Attribute",
            "$id": "#attributeEnumSet",
            "allOf": [
              {
                "oneOf": [
                  {
                    "const": "attributeEnumSet.presentValue",
                    "title": "Present Value",
                    "memberId": 85
                  }
                ]
              },
              {
                "$ref": "https://welchoas/api/v3/schemas/enums/attributeEnumSet"
              }
            ],
            "setId": 509
          },
          "writePriorityEnumSet_endAt_17": {
            "$schema": "http://json-schema.org/draft-07/schema#",
            "title": "Write Priority",
            "$id": "#writePriorityEnumSet_endAt_17",
            "allOf": [
              {
                "oneOf": [
                  {
                    "const": "writePriorityEnumSet.priorityNone",
                    "title": "0 (No Priority)",
                    "memberId": 0
                  },
                  {
                    "const": "writePriorityEnumSet.priorityManualEmergency",
                    "title": "1 (Manual Life Safety)",
                    "memberId": 1
                  },
                  {
                    "const": "writePriorityEnumSet.priorityFireApplications",
                    "title": "2 (Auto Life Safety)",
                    "memberId": 2
                  },
                  {
                    "const": "writePriorityEnumSet.priority3",
                    "title": "3 (Application)",
                    "memberId": 3
                  },
                  {
                    "const": "writePriorityEnumSet.priority4",
                    "title": "4 (Application)",
                    "memberId": 4
                  },
                  {
                    "const": "writePriorityEnumSet.priorityCriticalEquipment",
                    "title": "5 (Critical Equipment)",
                    "memberId": 5
                  },
                  {
                    "const": "writePriorityEnumSet.priorityMinimumOnOff",
                    "title": "6 (Minimum On Off)",
                    "memberId": 6
                  },
                  {
                    "const": "writePriorityEnumSet.priorityHeavyEquipDelay",
                    "title": "7 (Heavy Equip Delay)",
                    "memberId": 7
                  },
                  {
                    "const": "writePriorityEnumSet.priorityOperatorOverride",
                    "title": "8 (Operator Override)",
                    "memberId": 8
                  },
                  {
                    "const": "writePriorityEnumSet.priority9",
                    "title": "9 (Application)",
                    "memberId": 9
                  },
                  {
                    "const": "writePriorityEnumSet.priority10",
                    "title": "10 (Application)",
                    "memberId": 10
                  },
                  {
                    "const": "writePriorityEnumSet.priorityDemandLimiting",
                    "title": "11 (Demand Limiting)",
                    "memberId": 11
                  },
                  {
                    "const": "writePriorityEnumSet.priority12",
                    "title": "12 (Application)",
                    "memberId": 12
                  },
                  {
                    "const": "writePriorityEnumSet.priorityLoadRolling",
                    "title": "13 (Load Rolling)",
                    "memberId": 13
                  },
                  {
                    "const": "writePriorityEnumSet.priority14",
                    "title": "14 (Application)",
                    "memberId": 14
                  },
                  {
                    "const": "writePriorityEnumSet.prioritySchedulingOst",
                    "title": "15 (Scheduling)",
                    "memberId": 15
                  },
                  {
                    "const": "writePriorityEnumSet.priorityDefault",
                    "title": "16 (Default)",
                    "memberId": 16
                  }
                ]
              },
              {
                "$ref": "https://welchoas/api/v3/schemas/enums/writePriorityEnumSet"
              }
            ],
            "setId": 1
          }
        }
      }
    },
    {
      "id": "commandIdEnumSet.releaseAllCommand",
      "invokeUrl": "https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands/commandIdEnumSet.releaseAllCommand",
      "title": "Release All",
      "commandBodySchema": {
        "type": "object",
        "metasysType": "struct",
        "properties": {
          "parameters": {
            "type": "array",
            "metasysType": "list",
            "items": [
              {
                "id": "commandParmsEnumSet.attributeCmdparm",
                "title": "Attribute",
                "type": "string",
                "metasysType": "enum",
                "oneOf": [
                  {
                    "$ref": "#attributeEnumSet"
                  }
                ],
                "default": "attributeEnumSet.presentValue"
              }
            ],
            "minItems": 1,
            "maxItems": 1
          },
          "annotation": {
            "title": "Annotation",
            "type": "string",
            "metasysType": "string",
            "minLength": 1,
            "maxLength": 255
          },
          "required": [],
          "additionalProperties": false
        },
        "definitions": {
          "attributeEnumSet": {
            "$schema": "http://json-schema.org/draft-07/schema#",
            "title": "Attribute",
            "$id": "#attributeEnumSet",
            "allOf": [
              {
                "oneOf": [
                  {
                    "const": "attributeEnumSet.presentValue",
                    "title": "Present Value",
                    "memberId": 85
                  }
                ]
              },
              {
                "$ref": "https://welchoas/api/v3/schemas/enums/attributeEnumSet"
              }
            ],
            "setId": 509
          }
        }
      }
    },
    {
      "id": "commandIdEnumSet.enableAlarmsCommand",
      "invokeUrl": "https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands/commandIdEnumSet.enableAlarmsCommand",
      "title": "Enable Alarms",
      "commandBodySchema": {
        "type": "object",
        "metasysType": "struct",
        "properties": {
          "annotation": {
            "title": "Annotation",
            "type": "string",
            "metasysType": "string",
            "minLength": 1,
            "maxLength": 255
          },
          "required": [],
          "additionalProperties": false
        },
        "definitions": null
      }
    },
    {
      "id": "commandIdEnumSet.disableAlarmsCommand",
      "invokeUrl": "https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands/commandIdEnumSet.disableAlarmsCommand",
      "title": "Disable Alarms",
      "commandBodySchema": {
        "type": "object",
        "metasysType": "struct",
        "properties": {
          "annotation": {
            "title": "Annotation",
            "type": "string",
            "metasysType": "string",
            "minLength": 1,
            "maxLength": 255
          },
          "required": [],
          "additionalProperties": false
        },
        "definitions": null
      }
    }
  ],
  "effectivePermissions": {
    "canInvoke": [
      "commandIdEnumSet.adjustCommand",
      "commandIdEnumSet.overrideCommand",
      "commandIdEnumSet.temporaryOverrideCommand",
      "commandIdEnumSet.overrideReleaseCommand",
      "commandIdEnumSet.releaseCommand",
      "commandIdEnumSet.releaseAllCommand",
      "commandIdEnumSet.enableAlarmsCommand",
      "commandIdEnumSet.disableAlarmsCommand"
    ]
  }
}
```

</details>


The details of the response are outside of the scope of this tutorial, but we do see the `adjustCommand` in the response and we see that it's body is expected to be an object with a `parameters` property. The definition of `parameters` tells us it needs to be an array with one numeric value. So we can do the following.

```bash
> Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba/commands/adjustCommand -Method Put -Body "{ 'parameters': [ 72.5 ] }"

"Success"
```

### Creating an Object (POST)

For our last example we'll create a new AV.





### Clearing Credentials

Once you've authenticated against a site, your credentials are securely stored in your operating systems keychain. If your credentials ever change, you'll want to remove the saved credentials from the keychain. You can do this with the `DeleteCredentials` parameter. For example, if your credentials for the host named `adx32` have changed you'd run this command to delete them.

```bash
> Invoke-MetasysMethod -DeleteCredentials adx32
```


### Clearing a Session

Sometimes you want to talk to another site. This can be done by running `Invoke-MetasysMethod` in a separate instance of your terminal. Or you can reset your session by doing the following:

```bash
> Invoke-MetasysMethod -Clear
```

This clears all session saved variables. The next call you make you'll again be prompted for a site:

```bash
> Invoke-MetasysMethod /enumerations

Site host: welchoas
```

## Troubleshooting

### Invalid Certificates

This command will fail to execute if the server you are executing against doesn't have a valid certificate. A parameter is provided, `SkipCertificateCheck`, which causes all validation checks to be skipped. This includes all validations such as expiration, revocation, trusted root authority, etc. **WARNING** Using this parameter is not secure and is not recommended. This switch is intended to be used against known hosts using a self-signed certificate for testing purposes. *Use at your own risk*.





## Known Limitations

### Session Timeout

`Invoke-MetasysMethod` tries to ensure your session doesn't timeout. But if you don't issue a command for a certain amount of time, your session will expire. After that point any calls will fail with an `Unauthorized` error. For example this following call would normally work if my session was still active.

```bash
Invoke-MetasysMethod /objects/ce820989-5617-50bd-90ea-2fd95d1402ba

Invoke-MetasysMethod: Status: 401 (Unauthorized)
Cache-Control: no-store, must-revalidate, no-cache, max-age=0, s-maxage=0, pre-check=0, post-check=0
Pragma: no-cache no-cache
Set-Cookie: Secure; HttpOnly
Strict-Transport-Security: max-age=31536000
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Date: Fri, 02 Jul 2021 14:26:09 GMT
Content-Type: application/vnd.metasysapi.v4+json
Expires: -1
Content-Length: 61
{"Message":"Authorization has been denied for this request."}
```

To resolve this issue simply run `Invoke-MetasysMethod` with the `Login` switch to force a new login and new session.

```bash
> Invoke-MetasysMethod -Login

Site host: welchoas
```

Since your credentials are cached a future release of `Invoke-MetasysMethod` should be able to do this for you.

### Only supports One Account Per Site

Only one set of credentials are saved per site. So if you are testing with multiple user accounts, you'll need to specify which user you are using with the `UserName` parameter.
