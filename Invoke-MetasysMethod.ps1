param(
    [string]$Site,
    [string]$UserName,
    [switch]$Login,
    [string]$Path,
    [switch]$Clear,
    [string]$Body,
    [string]$Method = "Get",
    [Int]$Version = 3,
    [switch]$SkipCertificateCheck,
    [string]$Reference
)
Import-Module -Name ./Invoke-MetasysMethod
Invoke-MetasysMethod -Site $Site -UserName $UserName -Path $Path -Body $Body -Method $Method -Version $Version -Reference $Reference
