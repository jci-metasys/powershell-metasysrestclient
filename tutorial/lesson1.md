# Easy Metasys API Access

The Invoke-MetasysMethod module comes with a handful of helper functions and aliases to cut down on how much typing you need to do.

To run through this tutorial you will need access to a site with a server as site director and credentials for that server.

This tutorial will cover two scenarios

1. Interrogating an object, writing to it, and then sending it a command.
2. Searching alarms

## Dealing with Objects

In this tutorial we'll use the aliases mget-object, mwrite, and msend-command.

### Reading an Object

The first command we'll enter is `mget-object thesun:thesun`

```powershell
PS > mget-object thesun:thesun
Site: thesun.cg.na.jci.com
UserName: Michael
Password: **********

self                 : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf                        0-5533-8e67-f74bb728bf18?includeSchema=false&viewId=view
                       NameEnumSet.focusView
objectType           : objectTypeEnumSet.adsClass
```

What happened after we entered the command is that we were prompted for the hostname of the site director as well as our credentials. These are used to acquire a key which is stored as an encrypted string in a process environment variable. This key will be used for a future calls (until the session expires).

Now what was returned was a lot of data.

<details><summary>Click here to see the full reponse</summary>

```text
self                 : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf                        0-5533-8e67-f74bb728bf18?includeSchema=false&viewId=view
                       NameEnumSet.focusView
objectType           : objectTypeEnumSet.adsClass
parentUrl            : https://thesun.cg.na.jci.com/api/v3/objects/8e16a75e-20e
                       8-55bd-ac11-926c1122d69c
objectsUrl           : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf
                       0-5533-8e67-f74bb728bf18/objects
networkDeviceUrl     :
pointsUrl            : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf
                       0-5533-8e67-f74bb728bf18/points
trendedAttributesUrl : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf
                       0-5533-8e67-f74bb728bf18/trendedAttributes
alarmsUrl            : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf
                       0-5533-8e67-f74bb728bf18/alarms
auditsUrl            : https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf
                       0-5533-8e67-f74bb728bf18/audits
item                 : @{attrChangeCount=0; name=thesun; description=The Sun
                       Server; bacnetObjectType=objectTypeEnumSet.adsClass;
                       objectCategory=objectCategoryEnumSet.systemCategory;
                       version=; modelName=ADS; localTime=; localDate=;
                       itemReference=thesun:thesun; fipsComplianceStatus=noOfCo
                       mplianceStateEnumSet.nonCompliantUnlicensed;
                       almSnoozeTime=5; auditEnabledClasLev=2;
                       addAdsrepos=System.Object[];
                       adsRepositoriesStatus=System.Object[]; sampleRate=0;
                       serviceTime=56; numberOfNxesReporting=8;
                       transferBufferFullWorstNxe=16; hostName=Uranus3201;
                       isValidated=False;
                       id=c05d5d30-ebf0-5533-8e67-f74bb728bf18}
views                : {@{title=Focus; views=System.Object[];
                       id=viewNameEnumSet.focusView}}
condition            :
```

</details>

This is a compressed version of the response. A lot of details are not shown. All of the interesting attributes of an object are stored in the `"item"` property. Let's run the command a second time and this time store the results in a variable.

```powershell
PS > $serverObject = mget-object thesun:thesun
```

Notice we weren't prompted for any information this time. The shell has remembered the site and the access key.

Let's examine some properties of the object now.

```powershell
PS > $serverObject.self
https://thesun.cg.na.jci.com/api/v3/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18?includeSchema=false&viewId=viewNameEnumSet.focusView
```

This `self` property is the URL used to access this object. We can test this URL using the `Invoke-MetasysMethod` function. But this function already fills in the first part of the URL for us. It just needs us to pass in the part of the URL after the version number.

```powershell
PS > Invoke-MetasysMethod -Method GET -Path "/objects/c05d5d30-ebf0-5533-8e67-f74bb728bf18?includeSchema=false&viewId=viewNameEnumSet.focusView"
```

This will return the same response as `mget-object`.
Notice I used quotes around the path. This is because there are some special characters like `&` in the string that powershell treats specially.



