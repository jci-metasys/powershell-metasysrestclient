# TODO List

Add utility methods

- [ ] New-MetasysObject -LocalUniqueIdentifier -ParentId -ObjectType
      [-Properties @{ }]
- [ ] Find-MetasysObject -ObjectType [-Count X] [-DeviceId X] [-Name {regex}]
      [-Depth xxx]
- [ ] Send-MetasysCommand -ObjectId -CommandId -Parameters -Annotation -Priority
- [ ] Read-MetasysObject -ObjectId [-ViewId]
- [ ] Read-MetasysAttribute -ObjectId -AttributeId [-RawValue] // Raw value will
      just display the value, no JSON, no condition, etc.
- [ ] Get-Objects [-ObjectId objectId]

## Design Philosophy

All previous versions were mainly concerned with a user (primarily myself)
interested in calling an operation to be able to see the JSON result (or test
JSON requests). It's not clear to me whether this client is useful for writing
applications or scripts.

Some things it's probably missing for a good script

- The base command probably needs a better way to return errors. Currently, the
  focus is on just returning the body of the response message. If this is an
  error payload it's displayed just like the response body of a non-error
  payload.

  - One possibility would be to throw an exception that contains the full
    response object.
  - some errors (like networking errors) just fail with a Write-Error and then
    exit. These should probably throw as well

  The problem with throwing errors is that they are ugly on the screen. They
  work well for scripts/applications but for me using it on the command line I
  don't see seeing so much red.

  Perhaps what I need to do is create one version of Invoke-MetasysMethod that
  is for applications and another that is a wrapper that can catch the ugly
  error messages and customize the output.

- There has only been the base command up til now (Aug. 2024). I'm in the
  process of adding subcommands for common operations or operations that require
  a body where you may not remember the schema of the body. So possible
  operations in the first releases

  - Common operations
    - ReadAttribute/ReadAttributes
    - SendCommand
    - GetObjectView
    - WriteAttribute/WriteAttributes
    - GetObjects (discover the tree)
  - Body operations
    - Create object
    - Create enum
    - Edit enum

  For sub-commands I want to concentrate on application usage. Rather than focus
  on returning JSON they should return objects. (Because if I just want JSON I
  could call the base command). The sub commands are meant to offer a higher
  level of abstraction.

  For example, let's consider ReadAttribute and what it should return

  - Return just the raw value of the attribute. For example (`$true`, `68.0`,
    `"ADS:ADS"`, `127,23,15,14`). There are two approaches here as well. We
    could focus on just relying on the JSON types which is known from the JSON
    itself, or we could always ask for the schema and know the precise
    `metasys-type`. I think I'd lean on the second. In this scenario the
    response type would best be considered `object`.
  - The next option is to do the same but explicitly create a Variant type that
    works much like JToken types in JSON libraries. You can inspect the Variant
    and determine what it contains and then extract out the right value. This
    would be nicer if Powershell supported pattern matching. In practice, this
    is unlikely to be an issue as many use cases the user knows that they are
    reading (say presentValue) and the result type is known or its known to be
    either an enum or a float.
  - A third option is for the fact that we normally care about
    status/reliability/priority etc of a value. So perhaps we should return a
    AttributeValue class that includes the condition flags as well as the value.
    It could even include other schema information (like min/max values etc.)

  I am leaning towards option 3 where the `Value` is a `Variant` (or we could
  call it a `MetasysValue`)
