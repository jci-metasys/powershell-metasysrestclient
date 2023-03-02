# Changelog

<!-- markdownlint-disable-file no-duplicate-heading -->

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Add specialized functions (`New-MetasysObject`, `Get-MetasysPresentValue`,
  `Send-MetasysCommand`, ...)

## [2.2.0-rc2] - 2023-03-01

### Added

- Add support for a config file to provide an alias for hosts, along with other
  connection properties (`alias`, `hostname`, `username`, `version`,
  `skip-certificate-check`)

  - Add new positional parameter -Alias (you can now make a connection as simply
    as `cma {alias}`)
  - Add tab completion for -Alias parameter

- A new information stream message when attempting to reconnect
- Repo now has an automated unit test workflow on pr and merge to main
- Added user preference for METASYS_SKIP_CHECK_NOT_SECURE
- Add support for response content types of type `text/*`

### Changed

- Change version parameter to string and remove validation
- Update docs to note that any cli parameters supplied to Connect-MetasysAccount
  override there related properties found in the config file.

### Fixed

- Issues with "boolean" environment variables not back to booleans correctly
- Issue in tests that relied on order of headers
- Issue in checking to see if secret management/secret store is installed and
  configured
- Issue in clearing env variables between runs and between tests
- Issue in tests where different versions of $LatestVersion were used
- Issues in tests where user preferences were not accounted for or honored

## [2.1.2] - 2022-06-21

### Changed

- Fix a bug in Get-SavedMetasysUsers which corrupted the output a little
- Only attempt to change background colors when running in console mode. Else
  when running in the background (say as part of a cron job) there is no console
  to access and the job would error out.
- Update help for Connect-MetasysAccount to explain how versioning works
- If secrete vault is not configured write out information message rather than
  warning

## [2.1.0] - 2022-01-24

### Added

- Add support for `v5` of the API in `Version` switch
- Add support for `$env:METASYS_DEFAULT_API_VERSION`

### Changed

- Finish converting `SiteHost` to `MetasysHost` in all of the exposed methods of
  this module.

## [2.0.0] - 2021-11-18

### Added

- Add -IncludeResponseHeaders switch
- Add tests

### Breaking

- Separate the "login" function into new method `Connect-MetasysAccount`

### Change

- Change `SiteHost` switch to `MetasysHost` (SiteHost left as an alias)

## [1.0.0] - 2021-08-11

No changes since alpha 3

## [1.0.0-alpha3] - 2021-07-24

### Added

- Add aliases for `Invoke-MetasysMethod` parameters

## [1.0.0-alpha2] - 2021-07-24

### Added

- Added a changelog

### Changed

- If a request to a site throws an exception, `Invoke-MetasysMethod` will now
  print error and halt immediately. Previously, it would continue leading to
  more reported errors

## [1.0.0-alpha1] - 2021-07-16

### Added

- `Invoke-MetasysMethod` function which is a wrapper around `Invoke-WebRequest`
- `Invoke-MetasysMethod` keeps a "session" open to reduce the amount of
  parameters that would need to be passed to `Invoke-WebRequest`
- Optional use of `SecretManagement` if it's installed and configured to save
  credentials
- Secret management functions like `Get-SavedMetasysUsers` and
  `Set-SavedMetasysPassword`

[unreleased]:
  https://github.com/metasys-server/powershell-metasysrestclient/compare/v2.2.0-rc1...HEAD
[2.2.0-rc2]:
  https://github.com/metasys-server/powershell-metasysrestclient/compare/v2.1.2...v2.2.0-rc2
[2.1.2]:
  https://github.com/metasys-server/powershell-metasysrestclient/compare/v2.1.0...v2.1.2
[2.1.0]:
  https://github.com/metasys-server/powershell-metasysrestclient/compare/v2.0.0...v2.1.0
[2.0.0]:
  https://github.com/metasys-server/powershell-metasysrestclient/compare/v1.0.0...v2.0.0
[1.0.0]:
  https://github.com/metasys-server/powershell-metasysrestclient/compare/v1.0.0-alpha3...v1.0.0
[1.0.0-alpha3]:
  https://github.com/metasys-server/powershell-metasysrestclient/compare/v1.0.0-alpha2...v1.0.0-alpha3
[1.0.0-alpha2]:
  https://github.com/metasys-server/powershell-metasysrestclient/compare/v1.0.0-alpha1...v1.0.0-alpha2
[1.0.0-alpha1]:
  https://github.com/metasys-server/powershell-metasysrestclient/releases/tag/v1.0.0-alpha1
