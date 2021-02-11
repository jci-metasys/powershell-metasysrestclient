param(
    [string]$SiteHost,
    [string]$UserName,
    [switch]$Login,
    [string]$Path,
    [switch]$Clear,
    [string]$Body,
    [string]$Method = "Get",
    [Int]$Version = 4,
    [switch]$SkipCertificateCheck,
    [string]$Reference
)
Import-Module -Force -Name ./Invoke-MetasysMethod
Invoke-MetasysMethod -SiteHost $SiteHose -UserName $UserName -Path $Path -Body $Body -Method $Method -Version $Version -Reference $Reference
