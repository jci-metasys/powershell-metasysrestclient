Set-StrictMode -Version 3
Set-Variable -Name LatestVersion -Value 4 -Option Constant
function Connect-MetasysAccount {
    <#
    .Synopsis
    Connect to Metasys with an authenticated account for use with functions in MetasysRestClient module
    #>
    param(
        [Alias("h", "host")]
        [String]$MetasysHost,
        [Alias("u")]
        [String]$UserName,
        [Alias("p")]
        [SecureString]$Password,
        [Alias("v")]
        [ValidateRange(2, 4)]
        [Int32]$Version
    )

    Clear-MetasysEnvVariables

    if (!$MetasysHost) {
        $MetasysHost = Read-Host -Prompt "Metasys Host"
    }

    if (!$UserName) {
        $users = Get-SavedMetasysUsers -SiteHost $MetasysHost

        if ($users -and $users.Count -eq 1) {
            $UserName = $users | Select-Object -ExpandProperty UserName
        }
        else {
            $UserName = Read-Host -Prompt "UserName"
        }
    }

    if (!$Password) {

        $Password = (Get-SavedMetasysPassword -SiteHost $MetasysHost -UserName $UserName) ?? (Read-Host -Prompt "Password" -AsSecureString)
    }

    if (!$Version) {
        $Version = $LatestVersion
    }

    $body = @{
        username = $UserName;
        password = ConvertFrom-SecureString -AsPlainText $Password
    } |  ConvertTo-Json

    $uri = "https://$MetasysHost/api/v$Version/login"
    $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' -Body $body
    $env:METASYS_ACCESS_TOKEN = $response.accessToken | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
    $env:METASYS_EXPIRES = $response.expires
    $env:METASYS_HOST = $MetasysHost
    $env:METASYS_VERSION = $Version
}

Set-Alias -Name cmsa -Value Connect-MetasysAccount

Export-ModuleMember -Function Connect-MetasysAccount
Export-ModuleMember -Alias cmsa
