
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

function Set-MetasysSkipSecureCheckNotSecure {
    $env:METASYS_SKIP_CHECK_NOT_SECURE = $true
}

function Reset-MetasysSkipSecureCheckNotSecure {
    $env:METASYS_SKIP_CHECK_NOT_SECURE = $null
}

function Get-MetasysSkipSecureCheckNotSecure {

    if ($env:METASYS_SKIP_CHECK_NOT_SECURE -eq 'True') {
        $true
    }
    else {
        $false
    }
}

Export-ModuleMember -Function 'Set-MetasysDefaultApiVersion', 'Get-MetasysDefaultApiVersion',
'Set-MetasysSkipSecureCheckNotSecure', 'Reset-MetasysSkipSecureCheckNotSecure', 'Get-MetasysSkipSecureCheckNotSecure'
