
<#
Preferences are writable by our users, but we should treat
them as read-only.
#>

function Set-MetasysDefaultApiVersion {
    param (
        [string]$Version
    )
    $env:METASYS_DEFAULT_API_VERSION = $Version
}

function Get-MetasysDefaultApiVersion {
    $env:METASYS_DEFAULT_API_VERSION
}

Export-ModuleMember -Function 'Set-MetasysDefaultApiVersion', 'Get-MetasysDefaultApiVersion'
