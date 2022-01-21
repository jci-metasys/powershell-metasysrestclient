# MetasysRestClient

A PowerShell module that sends HTTPS request to a Metasys device running Metasys
REST API.

Features:

- Establishes a "session" with a Metasys device so you don't need to send
  credentials on each call or explicitly manage the access token
- Sets boiler plate like `Content-Type` header for you on each request
- Securely stores credentials in secret vault after your first successful login
  to a Metasys device (requires SecretManagement module and a Secret Vault to be
  installed and registered)
- Provides helper functions to inspect all the results of the previous command
- Provides helper functions to deal with responses as PowerShell objects rather
  than JSON
- Provides helper functions to make calling common methods even easier (in
  progress)

## Dependencies

- Powershell Core for your OS: See the
  [repository](https://github.com/powershell/powershell).

  **Note:** Windows PowerShell is not supported

- (Optional) Microsoft.PowerShell.SecretManagement
- (Optional) Microsoft.PowerShell.SecretStore (or other SecretVault
  implementation)

## Credential Management

If you install and configure SecretManagement and a Secret Vault, your
credentials will be securely saved between sessions. See
[Secret Management](docs/secret-management.md).

## Prerequisites

This guide assumes you have some familiarity with REST APIs in general and the
Metasys REST API specifically.

See the Documentation for the Metasys REST API for more information on what
endpoints are available and what their payloads look like.

To become really proficient with this tool you'll want to learn PowerShell. But
this guide doesn't assume you know PowerShell and the documentation will be
updated to help you do the most common actions.

## Metasys REST API Versions

Examples in this README are from `v4` of the API. However, Metasys Rest Client
works with `v2`, `v3` and `v5` as well.

## PowerShell References

- [Learning PowerShell](https://github.com/PowerShell/PowerShell/tree/master/docs/learning-powershell)
- [PowerShell Beginner’s Guide](https://github.com/PowerShell/PowerShell/blob/master/docs/learning-powershell/powershell-beginners-guide.md)

## Installation

From a powershell command prompt:

```powershell
PS > Install-Module MetasysRestClient -Repository PSGallery
```

## Help

You can discover the commands in the module by ensuring it has been loaded and
then inspecting it's contents:

```powershell
PS > Import-Module MetasysRestClient
PS > (Get-Module MetasysRestClient).ExportedCommands

Key                                 Value
---                                 -----
Clear-MetasysEnvVariables           Clear-MetasysEnvVariables
Connect-MetasysAccount              Connect-MetasysAccount
Get-LastMetasysHeadersAsObject      Get-LastMetasysHeadersAsObject
Get-LastMetasysResponseBodyAsObject Get-LastMetasysResponseBodyAsObject
Get-SavedMetasysPassword            Get-SavedMetasysPassword
Get-SavedMetasysUsers               Get-SavedMetasysUsers
Invoke-MetasysMethod                Invoke-MetasysMethod
Remove-SavedMetasysPassword         Remove-SavedMetasysPassword
Set-SavedMetasysPassword            Set-SavedMetasysPassword
Show-LastMetasysAccessToken         Show-LastMetasysAccessToken
Show-LastMetasysFullResponse        Show-LastMetasysFullResponse
Show-LastMetasysHeaders             Show-LastMetasysHeaders
Show-LastMetasysResponseBody        Show-LastMetasysResponseBody
Show-LastMetasysStatus              Show-LastMetasysStatus
cma                                 cma
imm                                 imm
```

You can find help on any of the commands using `help`

```powershell
PS > help Invoke-MetasysMethod
```

## Quick Start

This section will show you the basics of using `Invoke-MetasysMethod`. We will
cover

- Starting a Session
- Discovering objects
- Reading an object and an attribute
- Sending a command
- Creating an object

### Starting a Session

To get started you need to get logged into a site.

To do this, call `Connect-MetasysAccount` with no parameters. You'll be prompted
for your `Metasys host`, `UserName` and `Password`.

```powershell
PS > Connect-MetasysAccount

Metasys host: welchoas
UserName: api
Password: *********
```

**Note:** If you wish to control which version of the REST API will be used, you
can specify it with the `-Version` switch.

```powershell
PS > Connect-MetasysAccount -Version 3
```

If you don't specify a version, then `Connect-MetasysAccount` will look for the
environment variable `$env:METASYS_DEFAULT_API_VERSION`. If that variable is not
set, it will default to a version. At the time of writing, that version is 5.

Whatever version is used in the call to `Connect-MetasysAccount` will be used
for all other calls in the current session (unless overridden with `-Version`
switch or by specifying a full URL).

#### Starting a Session without Prompts

If you want to start a session without being prompted for `Metasys Host`,
`UserName`, and `Password` you can supply them all as parameters. You should
also specify the `Version` on this first call to be explicit about which version
of the API you want. The default value of this parameter is `5`.

```powershell
PS > $password = Get-SavedMetasysPassword -MetasysHost welchoas -UserName api
PS > Connect-MetasysAccount -MetasysHost welchoas -UserName api -Password $password -Version 3
```

This will start a session using version 3 of the API. You don't need to specify
the version for other calls made during this session. `Invoke-MetasysMethod`
remembers what version you requested and uses it for future calls. The
`Password` parameter takes as input a `SecureString`. Typically you'd want to
retrieve it from some secret storage that returns a `SecureString`. In this
example we looked it up using `Get-SavedMetasysPassword`. See
[SecretManagement](docs/secret-management.md) for more details.

### Reading Information (GET)

When you want to read information from Metasys you'll normally be doing a `GET`
request. These are the easiest to work with because they only require a URL and
nothing else. You can use a relative or absolute url.

```powershell
PS > Invoke-MetasysMethod /objects
```

This will invoke the `/objects` endpoint and display the response body. Notice
that we were not prompted for any information because we established a session
in the previous step. (If we had skipped that step then we would have been given
an error message.)

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

An _absolute url_ looks like `https://{hostname}/api/v4/objects`. Many API
endpoints return absolute URLs in their response payloads. These are used to
provide information about other useful resources on the system. So it's
convenient to be able to copy and paste those to make another request.

In the example above, the `self` property of the last object is
`https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b`. Let's
use that absolute url to read the default view of that object.

```powershell
PS > Invoke-MetasysMethod https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b
```

<details><summary>Click to See Response</summary>

```json
{
  "self": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b?includeSchema=false&viewId=viewNameEnumSet.focusView",
  "objectType": "objectTypeEnumSet.oasClass",
  "parentUrl": "https://welchoas/api/v4/objects/896f7c45-de4b-5a2c-9084-bceb0ec85962",
  "objectsUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/objects",
  "networkDeviceUrl": null,
  "pointsUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/points",
  "trendedAttributesUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/trendedAttributes",
  "alarmsUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/alarms",
  "auditsUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b/audits",
  "item": {
    "id": "8f2c6bb1-6bfd-5643-b581-299c1fec6b1b",
    "name": "welchoas",
    "description": null,
    "bacnetObjectType": "objectTypeEnumSet.bacdeviceClass",
    "objectCategory": "objectCategoryEnumSet.generalCategory",
    "modelName": "OAS",
    "localTime": {
      "hour": 16,
      "minute": 58,
      "second": 41,
      "hundredth": 56
    },
    "localDate": {
      "year": 2021,
      "month": 7,
      "dayOfMonth": 5,
      "dayOfWeek": 1
    },
    "firmwareVersion": "12.0.0.6218",
    "itemReference": "welchoas:welchoas",
    "version": {
      "major": 37,
      "minor": 0
    },
    "archiveDate": {
      "year": 2021,
      "month": 7,
      "dayOfMonth": 5,
      "dayOfWeek": 1
    },
    "maxMessageBuffer": 994.0,
    "maxApduLength": 1024.0,
    "apduSegmentTimeout": 10000.0,
    "apduTimeout": 10000.0,
    "apduRetries": 4.0,
    "internodeCommTimer": 120.0,
    "unboundReferences": [],
    "duplicateReferences": [],
    "fipsComplianceStatus": "noOfComplianceStateEnumSet.nonCompliantUnlicensed",
    "almSnoozeTime": 5.0,
    "enableApplicationGenAudit": false,
    "auditEnabledClasLev": 2.0,
    "addAdsrepos": [],
    "adsRepositoriesStatus": [],
    "allowOffSiteRepositoryStorage": false,
    "sampleRate": 0.0,
    "serviceTime": 66.0,
    "numberOfNxesReporting": 1.0,
    "transferBufferFullWorstNxe": 0.0,
    "hostName": "",
    "jciExceptionSchedule": "weeklySchedPurgeEnumSet.wsAutoDelete31Days",
    "isValidated": false,
    "bacnetObjectCacheExposed": "bacnetObjectCacheExposedEnumSet.boceIncludeInList",
    "jciSystemStatus": "jciSystemStatusEnumSet.jciOperational",
    "status": "objectStatusEnumSet.osNormal",
    "attrChangeCount": 201.0,
    "defaultAttribute": "attributeEnumSet.jciSystemStatus"
  },
  "effectivePermissions": {
    "canDelete": false,
    "canModify": true
  },
  "views": [
    {
      "title": "Focus",
      "views": [
        {
          "title": "Basic",
          "views": [
            {
              "title": "Object",
              "properties": [
                "name",
                "description",
                "bacnetObjectType",
                "objectCategory",
                "modelName"
              ],
              "id": "viewGroupEnumSet.objectGrp"
            },
            {
              "title": "Time",
              "properties": ["localTime", "localDate"],
              "id": "viewGroupEnumSet.timeGrp"
            }
          ],
          "id": "groupTypeEnumSet.basicGrpType"
        },
        {
          "title": "Advanced",
          "views": [
            {
              "title": "Engineering Values",
              "properties": [
                "firmwareVersion",
                "itemReference",
                "version",
                "archiveDate",
                "maxMessageBuffer",
                "maxApduLength",
                "apduSegmentTimeout",
                "apduTimeout",
                "apduRetries",
                "internodeCommTimer",
                "unboundReferences",
                "duplicateReferences",
                "fipsComplianceStatus",
                "id"
              ],
              "id": "viewGroupEnumSet.engValuesGrp"
            },
            {
              "title": "Alarms",
              "properties": ["almSnoozeTime"],
              "id": "viewGroupEnumSet.alarmsGrp"
            },
            {
              "title": "Audit Trail",
              "properties": [
                "enableApplicationGenAudit",
                "auditEnabledClasLev"
              ],
              "id": "viewGroupEnumSet.auditTrailGrp"
            },
            {
              "title": "Repository Storage",
              "properties": [
                "addAdsrepos",
                "adsRepositoriesStatus",
                "allowOffSiteRepositoryStorage",
                "sampleRate",
                "serviceTime",
                "numberOfNxesReporting",
                "transferBufferFullWorstNxe",
                "hostName"
              ],
              "id": "viewGroupEnumSet.repositoryStorageGrp"
            },
            {
              "title": "Weekly Scheduling",
              "properties": ["jciExceptionSchedule"],
              "id": "viewGroupEnumSet.weeklySchedGrp"
            },
            {
              "title": "Validated Environment",
              "properties": ["isValidated"],
              "id": "viewGroupEnumSet.validatedEnvironmentGrp"
            },
            {
              "title": "BACnet Routing",
              "properties": ["bacnetObjectCacheExposed"],
              "id": "viewGroupEnumSet.routingGrp"
            }
          ],
          "id": "groupTypeEnumSet.advancedGrpType"
        },
        {
          "title": "Key",
          "views": [
            {
              "title": "None",
              "properties": [
                "jciSystemStatus",
                "status",
                "attrChangeCount",
                "defaultAttribute"
              ],
              "id": "viewGroupEnumSet.noGrp"
            }
          ],
          "id": "groupTypeEnumSet.keyGrpType"
        }
      ],
      "id": "viewNameEnumSet.focusView"
    }
  ],
  "condition": {}
}
```

</details>

A _relative url_ looks like `/objects`. In other words, it's everything after
`https://{hostname}/api/v4`.

In this next example we'll read the `presentValue` of an object. I happen to
know the `id` for this object is `ce820989-5617-50bd-90ea-2fd95d1402ba`.

```powershell
PS > Invoke-MetasysMethod https://welchoas/api/v4/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/attributes/presentValue

{
  "item": {
    "presentValue": 68.2
  },
  "condition": {
    "presentValue": {}
  }
}
```

This time we showed the use of an absolute url. We could have just used
`/objects/ce820989-5617-50bd-90ea-2fd95d1402ba/attributes/presentValue` instead.
Either type of url is fine.

Another good tip is to save identifiers in variables so you don't have to type
them multiple times or copy/paste them:

```powershell
PS > $Id = "ce820989-5617-50bd-90ea-2fd95d1402ba"
PS > Invoke-MetasysMethod https://welchoas/api/v4/objects/$Id/attributes/presentValue
```

Examples of other urls that support `GET`

- `/alarms` - Get first page of alarms
- `/audits` - Get first page of audits
- `/activities` - Get first page of the collection of all activities (the
  activities collection is a union of the alarms and audits collections)
- `/objects/$id/objects` - Get the child objects of the specified object where
  `$id` contains a valid object identifier.

### Writing An Object Attribute (PATCH)

In this example we'll change the value of an object attribute. This requires us
to use two new parameters. First we'll use the `Method` parameter to specify we
are sending a `PATCH` request, and we'll use the `Body` parameter to specify the
content we want to send.

Let's change the `description` attribute of the AV from the previous section.
Let's first read it to confirm it's currently `null`. Recall that we've saved
the identifier in the variable `$Id`.

```powershell
PS > Invoke-MetasysMethod /objects/$Id/attributes/description

{
  "item": {
    "description": null
    },
  "condition": {}
}
```

We'll change the value to be `Zone 3 Temperature Set Point`. We are going to
send this body to do that:

```json
{
  "item": {
    "description": "Zone 3 Temperature Set Point"
  }
}
```

It can be a little tricky dealing with large JSON strings. There are many ways
to construct them. See [Tips for Working With PowerShell](docs/tips.md) for
examples of working with JSON strings.

When the JSON string is relatively short like in this example you can just type
it all on one line:

```powershell
PS > Invoke-MetasysMethod -Method Patch /objects/$Id  -Body "{ 'item': { 'description': 'Zone 3 Temperature Set Point' } }"
```

We'll read it back to ensure it changed:

```powershell
PS > Invoke-MetasysMethod /objects/$Id/attributes/description
{
  "item": {
    "description": "Zone 3 Temperature Set Point"
  },
  "condition": {
    "description": {}
  }
}
```

### Using an Alias

Many of the built-in PowerShell commands have long names just like
`Invoke-WebRequest`. Many of those also have aliases that are much shorter (eg.
`iwr` for `Invoke-WebRequest`). The command `Invoke-MetasysMethod` also has an
alias, `imm`, which you can use instead of the full name. For the remainder of
this README we'll use `imm` instead of `Invoke-MetasysMethod`. The alias for
`Connect-MetasysAccount` is `cma`.

### Sending a Command to an Object (PUT)

In this example we'll send an `adjustCommand` command to an AV.

We can discover that the object supports `adjustCommand` by requesting the list
of commands:

```powershell
PS > imm /objects/$Id/commands
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
                "minimum": -1.69999997607218e38,
                "maximum": 1.69999997607218e38,
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
                "minimum": -1.69999997607218e38,
                "maximum": 1.69999997607218e38,
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
                "minimum": -1.69999997607218e38,
                "maximum": 1.69999997607218e38,
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

The details of the response are outside of the scope of this tutorial, but we do
see the `adjustCommand` in the response and we see that it's body is expected to
be an object with a `parameters` property. The definition of `parameters` tells
us it needs to be an array with one numeric value. So we can do the following.

```powershell
PS > imm /objects/$Id/commands/adjustCommand -Method Put -Body "{ 'parameters': [ 72.5 ] }"

"Success"
```

We could also add an annotation to the command:

```powershell
PS > $json = '{ "parameters": [72.5], "annotation": "Adjust Set Point for the afternoon" }'
PS > imm /objects/$Id/commands/adjustCommand -Method Put -Body $json
```

### Creating an Object (POST)

For this example we'll create a new AV. A typical payload to create an AV might
look something like this:

```json
{
  "localUniqueIdentifier": "Set Point",
  "parentId": "8f2c6bb1-6bfd-5643-b581-299c1fec6b1b",
  "objectType": "objectTypeEnumSet.avClass",
  "item": {
    "name": "Set Point",
    "objectCategory": "objectCategoryEnumSet.hvacCategory",
    "minPresValue": -50,
    "maxPresValue": 150,
    "units": "unitEnumSet.degF"
  }
}
```

We'll assume that JSON is stored in a file call `new-av.json` which is in the
same directory that we are running our commands from. (We'll use the
`Get-Content` command to read that file and provide it as the body. Be sure to
use the `Raw` switch so that `Get-Content` returns the whole file as one string,
rather than an array of strings -- one string per line).

```powershell
PS > imm /objects -Method Post -Body (Get-Content -Path new-av.json -Raw)
```

Notice that currently the creation of a new object doesn't return anything. So
how do we know if it was successful? There are some helper functions that allow
us to inspect the last response. I'll demonstrate three of them
`Show-LastMetasysStatus`, `Show-LastMetasysHeaders` and
`Show-LastMetasysFullResponse`

```powershell
# Show the status of last call
PS > Show-LastMetasysStatus
200 (OK)

# Show the headers of the last call
# Notice the Location header tells us the URL of the new object
PS > Show-LastMetasysHeaders
Content-Length: 0
Strict-Transport-Security: max-age=31536000
Date: Mon, 05 Jul 2021 23:07:21 GMT
Location: https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84
X-Content-Type-Options: nosniff
Pragma: no-cache,no-cache
X-XSS-Protection: 1; mode=block
Expires: -1
Cache-Control: private
Set-Cookie: Secure; HttpOnly

# Show the entire last response: status, headers, body
PS > Show-LastMetasysFullResponse
200 (OK)
Content-Length: 0
Strict-Transport-Security: max-age=31536000
Date: Mon, 05 Jul 2021 23:07:21 GMT
Location: https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84
X-Content-Type-Options: nosniff
Pragma: no-cache,no-cache
X-XSS-Protection: 1; mode=block
Expires: -1
Cache-Control: private
Set-Cookie: Secure; HttpOnly
```

**Note:** The status of `200` tells us everything was good and the `Location`
header from above gives the url we can use to read the object back.

```powershell
PS > imm https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84
```

<details><summary>Click to see response</summary>

```json
{
  "self": "https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84?includeSchema=false&viewId=viewNameEnumSet.focusView",
  "objectType": "objectTypeEnumSet.avClass",
  "parentUrl": "https://welchoas/api/v4/objects/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b",
  "objectsUrl": "https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84/objects",
  "networkDeviceUrl": "https://welchoas/api/v4/networkDevices/8f2c6bb1-6bfd-5643-b581-299c1fec6b1b",
  "pointsUrl": "https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84/points",
  "trendedAttributesUrl": "https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84/trendedAttributes",
  "alarmsUrl": "https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84/alarms",
  "auditsUrl": "https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84/audits",
  "item": {
    "id": "3fdb754b-4f6e-592e-9c1e-8b72ad51cb84",
    "name": "Set Point",
    "description": null,
    "bacnetObjectType": "objectTypeEnumSet.bacAvClass",
    "objectCategory": "objectCategoryEnumSet.hvacCategory",
    "outOfService": false,
    "reliability": "reliabilityEnumSet.reliable",
    "currentCommandPriority": null,
    "alarmState": "objectStatusEnumSet.osNormal",
    "overrideExpirationTime": {
      "date": null,
      "time": null
    },
    "presentValueWritable": "objectModeEnumSet.presentValueWritableWithPriority",
    "itemReference": "welchoas:welchoas/Set Point",
    "version": {
      "major": 1,
      "minor": 0
    },
    "prioritySupported": true,
    "minPresValue": -50.0,
    "maxPresValue": 150.0,
    "units": "unitEnumSet.degF",
    "displayPrecision": "displayPrecisionEnumSet.displayPrecisionPt1",
    "covIncrement": 0.01,
    "connectedToInternalApplication": "noYesEnumSet.fanNo",
    "presentValue": 0.0,
    "status": "objectStatusEnumSet.osNormal",
    "attrChangeCount": 50.0,
    "defaultAttribute": "attributeEnumSet.presentValue"
  },
  "effectivePermissions": {
    "canDelete": true,
    "canModify": true
  },
  "views": [
    {
      "title": "Focus",
      "views": [
        {
          "title": "Basic",
          "views": [
            {
              "title": "Object",
              "properties": [
                "name",
                "description",
                "bacnetObjectType",
                "objectCategory"
              ],
              "id": "viewGroupEnumSet.objectGrp"
            },
            {
              "title": "Status",
              "properties": [
                "outOfService",
                "reliability",
                "currentCommandPriority",
                "alarmState",
                "overrideExpirationTime",
                "presentValueWritable"
              ],
              "id": "viewGroupEnumSet.statusGrp"
            }
          ],
          "id": "groupTypeEnumSet.basicGrpType"
        },
        {
          "title": "Advanced",
          "views": [
            {
              "title": "Engineering Values",
              "properties": [
                "itemReference",
                "version",
                "prioritySupported",
                "minPresValue",
                "maxPresValue",
                "id"
              ],
              "id": "viewGroupEnumSet.engValuesGrp"
            },
            {
              "title": "Display",
              "properties": ["units", "displayPrecision", "covIncrement"],
              "id": "viewGroupEnumSet.displayGrp"
            },
            {
              "title": "Internal Logic Interface",
              "properties": ["connectedToInternalApplication"],
              "id": "viewGroupEnumSet.internalLogicIfGrp"
            }
          ],
          "id": "groupTypeEnumSet.advancedGrpType"
        },
        {
          "title": "Key",
          "views": [
            {
              "title": "None",
              "properties": [
                "presentValue",
                "status",
                "attrChangeCount",
                "defaultAttribute"
              ],
              "id": "viewGroupEnumSet.noGrp"
            }
          ],
          "id": "groupTypeEnumSet.keyGrpType"
        }
      ],
      "id": "viewNameEnumSet.focusView"
    }
  ],
  "condition": {}
}
```

</details>

Rather than rely on the `Show-` methods, we can use the
`-IncludeResponseHeaders` switch at the time we invoke the method and all of the
response headers will be shown when the request finishes.

```powershell
PS > imm /objects -Method Post -Body (Get-Content -Path new-av.json -Raw) -IncludeResponseHeaders

200 (OK)
Location: https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84
Expires: -1
Cache-Control: private
Strict-Transport-Security: max-age=31536000
Date: Fri, 21 Jan 2022 20:03:56 GMT
Pragma: no-cache,no-cache
Content-Length: 0
X-XSS-Protection: 1; mode=block
Set-Cookie: Secure; HttpOnly
X-Content-Type-Options: nosniff
```

### Delete an Object (DELETE)

Let's delete the previous object

```powershell
# There is no response body to this payload, use -IncludeResponseHeaders to see the results
PS > imm -Method Delete https://welchoas/api/v4/objects/3fdb754b-4f6e-592e-9c1e-8b72ad51cb84 -IncludeResponseHeaders

204 (NoContent)
X-XSS-Protection: 1; mode=block
Date: Mon, 05 Jul 2021 23:26:28 GMT
Pragma: no-cache,no-cache
Strict-Transport-Security: max-age=31536000
Expires: -1
Cache-Control: no-store, must-revalidate, no-cache, max-age=0, s-maxage=0, pre-check=0, post-check=0
X-Content-Type-Options: nosniff
Set-Cookie: Secure; HttpOnly
```

## Troubleshooting

### Invalid Certificates

This command will fail to execute if the server you are executing against
doesn't have a valid certificate. A parameter is provided,
`SkipCertificateCheck`, which causes all validation checks to be skipped. This
includes all validations such as expiration, revocation, trusted root authority,
etc. **WARNING** Using this parameter is not secure and is not recommended. This
switch is intended to be used against known hosts using a self-signed
certificate for testing purposes. _Use at your own risk_.

## Known Limitations
