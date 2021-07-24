# Changelog

<!-- markdownlint-disable-file no-duplicate-heading -->

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

* Add specialized functions (`New-MetasysObject`, `Get-MetasysPresentValue`, `Send-MetasysCommand`, ...)
* Add more informational messages (primarily to help in debugging) using `Write-Information`
* Add support for a config file with preferences

## [1.0.0-alpha3] - 2021-07-24

### Added

* Add aliases for `Invoke-MetasysMethod` parameters

## [1.0.0-alpha2] - 2021-07-24

### Added

* Added a changelog

### Changed

* If a request to a site throws an exception, `Invoke-MetasysMethod` will now print error
  and halt immediately. Previously, it would continue leading to more reported errors

## [1.0.0-alpha1] - 2021-07-16

### Added

* `Invoke-MetasysMethod` function which is a wrapper around `Invoke-WebRequest`
* `Invoke-MetasysMethod` keeps a "session" open to reduce the amount of parameters that would
  need to be passed to `Invoke-WebRequest`
* Optional use of `SecretManagement` if it's installed and configured to save credentials
* Secret management functions like `Get-SavedMetasysUsers` and `Set-SavedMetasysPassword`

[Unreleased]: https://github.com/metasys-server/powershell-metasysrestclient/compare/v1.0.0-alpha2...HEAD
[1.0.0-alpha3]: https://github.com/metasys-server/powershell-metasysrestclient/compare/v1.0.0-alpha2...v1.0.0-alpha3
[1.0.0-alpha2]: https://github.com/metasys-server/powershell-metasysrestclient/compare/v1.0.0-alpha1...v1.0.0-alpha2
[1.0.0-alpha1]: https://github.com/metasys-server/powershell-metasysrestclient/releases/tag/v1.0.0-alpha1
