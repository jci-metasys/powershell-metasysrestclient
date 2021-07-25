<#
Tests for ConnectMetasys

[ ] If Vault is not specified, don't use vault
[ ] If Host is not specified, prompt
[ ] If UserName is not specified, and unique username for host not found in vault, prompt
[ ] If Passowrd is not specified, and password for host/user not found in value, prompt
[ ] If Version is not specified, default to latest

[ ] Expect Invoke-RestMethod https://$host/api/v$version/api/log -Method Post -Body '{ "usernaem": "$username", "password": "$passwordPlainText"}

#>

<#

Combinations

#>
class MockConsole {
    static [string] $MetasysHostPrompt = "Metasys Host"
    static [string] $UserNamePrompt = "UserName"
    static [string] $PasswordPrompt = "Password"


    static [String] $DefaultMetasysHost = "testhost"
    static [String] $DefaultUserName = "testuser"
    static [SecureString] $DefaultPassword = (ConvertTo-SecureString "testpassword" -AsPlainText)

    [Hashtable]$Inputs = @{ }

    MockConsole() {
        $this.Inputs[[MockConsole]::MetasysHostPrompt] = [MockConsole]::DefaultMetasysHost
        $this.Inputs[[MockConsole]::UserNamePrompt] = [MockConsole]::DefaultUserName
        $this.Inputs[[MockConsole]::PasswordPrompt] = [MockConsole]::DefaultPassword
    }

    MockConsole([String]$SiteHost = $DefaultSiteHost, [string]$UserName = $DefaultUserName,
        [SecureString]$Password = $DefaultPassword) {

        $this.Inputs[[MockConsole]::MetasysHostPrompt] = $SiteHost
        $this.Inputs[[MockConsole]::UserNamePrompt] = $UserName
        $this.Inputs[[MockConsole]::PasswordPrompt] = $Password
    }

    [void] SetResponse([string]$Prompt, [object]$Response) {
        $this.Inputs[$Prompt] = $Response
    }

    [Object] ReadHost([String]$Prompt) {
        return $this.Inputs[$Prompt]
    }

    [String]GetUserName() {
        return $this.Inputs[[MockConsole]::UserNamePrompt]
    }

    [String]GetPasswordAsPlainText() {
        return $this.Inputs[[MockConsole]::PasswordPrompt] | ConvertFrom-SecureString -AsPlainText
    }

    [SecureString]GetPassword() {
        return $this.Inputs[[MockConsole]::PasswordPrompt]
    }

    [String]GetMetasysHost() {
        return $this.Inputs[[MockConsole]::MetasysHostPrompt]
    }
}





BeforeAll {
    $mod = Import-Module -Name ../src/MetasysRestClient -Force -PassThru

    Set-Variable -Name LatestVersion -Value 4 -Option Constant

    function CreateLoginResponse {
        param(
            [string]$accessToken = "test token",
            [DateTime]$expires = [DateTime]::UtcNow
        )
        @{
            accessToken = $accessToken;
            expires     = $expires.ToString("o")
        }
    }
}

Describe "Connect-Metasys" -Tag "Unit" {
    Describe "When Secret Vault does not have the credentials" {
        Context "No parameters supplied" {
            BeforeAll {
                Clear-MetasysEnvVariables
                $mockConsole = [MockConsole]::new()
                Mock Read-Host -ModuleName MetasysRestClient {
                    $mockConsole.ReadHost($Prompt)
                }

                $loginResponse = CreateLoginResponse
                Mock Invoke-RestMethod -ModuleName MetasysRestClient {
                    $loginResponse
                }

                Mock Get-SavedMetasysPassword -ModuleName MetasysRestClient
                Mock Get-SavedMetasysUsers -ModuleName MetasysRestClient

                # qualify with $script to avoid unused-vars warnings from PSScriptAnalyzer
                $script:response = Connect-MetasysAccount
            }

            AfterAll {
                Clear-MetasysEnvVariables
            }


            It "Should prompt for MetasysHost" {
                Should -Invoke Read-Host -ModuleName MetasysRestClient -ParameterFilter {
                    $Prompt -eq [MockConsole]::MetasysHostPrompt
                } -Times 1 -Exactly -Scope Context
            }

            It "Should prompt for UserName" {
                Should -Invoke Read-Host -ModuleName MetasysRestClient -ParameterFilter {
                    $Prompt -eq [MockConsole]::UserNamePrompt
                } -Times 1 -Exactly -Scope Context
            }

            It "Should prompt for Password" {
                Should -Invoke Read-Host -ModuleName MetasysRestClient -ParameterFilter {
                    $Prompt -eq [MockConsole]::PasswordPrompt
                } -Times 1 -Exactly -Scope Context
            }

            It "Should invoke Invoke-RestMethod with correct url, body, method and content type" {
                $expectedBody = @{
                    username = $mockConsole.GetUserName();
                    password = $mockConsole.GetPasswordAsPlainText();
                } | ConvertTo-Json -Compress

                Should -Invoke Invoke-RestMethod -ModuleName MetasysRestClient -ParameterFilter {
                    $Method -eq 'Post' -and
                    $ContentType -eq 'application/json' -and
                    $Uri.ToString() -eq "https://$($mockConsole.GetMetasysHost())/api/v$LatestVersion/login" -and
                    ($Body | ConvertFrom-Json | ConvertTo-Json -Compress) -eq $expectedBody

                } -Times 1 -Exactly -Scope Context
            }

            It 'Should set $env:METASYS_ACCESS_TOKEN as an encrypted string' {
                $env:METASYS_ACCESS_TOKEN | Should -Be (ConvertFrom-SecureString (ConvertTo-SecureString -AsPlainText $loginResponse.accessToken))
            }

            It 'Should set $env:METASYS_EXPIRES' {
                $env:METASYS_EXPIRES | Should -Be $loginResponse.expires
            }

            It 'Should set $env:METASYS_HOST' {
                $env:METASYS_HOST | Should -Be $mockConsole.GetMetasysHost()
            }

            It 'Should return nothing' {
                $script:response | Should -BeNullOrEmpty
            }

        }

        Context "When host, username, and password are passed as parameters" {
            BeforeAll {
                Clear-MetasysEnvVariables

                Mock Read-Host -ModuleName MetasysRestClient

                $loginResponse = CreateLoginResponse
                Mock Invoke-RestMethod -ModuleName MetasysRestClient {
                    $loginResponse
                }

                $script:metasysHost = "aHost"
                $script:userName = "aUser"
                $script:securePassword = "aPassword" | ConvertTo-SecureString -AsPlainText

                # qualify with $script to avoid unused-vars warnings from PSScriptAnalyzer
                $script:response = Connect-MetasysAccount -MetasysHost $script:metasysHost `
                    -UserName $script:userName -Password $script:securePassword
            }

            AfterAll {
                Clear-MetasysEnvVariables
            }

            It "Should not prompt for anything" {
                Should -Invoke Read-Host -ModuleName MetasysRestClient -Times 0 -Exactly
            }

            It "Should invoke Invoke-RestMethod with correct url, body, method and content type" {
                $expectedBody = @{
                    username = $script:userName
                    password = $script:securePassword | ConvertFrom-SecureString -AsPlainText
                } | ConvertTo-Json -Compress

                Should -Invoke Invoke-RestMethod -ModuleName MetasysRestClient -ParameterFilter {
                    $Method -eq 'Post' -and
                    $ContentType -eq 'application/json' -and
                    $Uri.ToString() -eq "https://$($script:metasysHost)/api/v$LatestVersion/login" -and
                    ($Body | ConvertFrom-Json | ConvertTo-Json -Compress) -eq $expectedBody

                } -Times 1 -Exactly -Scope Context
            }

            It 'Should set $env:METASYS_ACCESS_TOKEN' {
                $env:METASYS_ACCESS_TOKEN | Should -Be (ConvertFrom-SecureString (ConvertTo-SecureString -AsPlainText $loginResponse.accessToken))
            }

            It 'Should set $env:METASYS_EXPIRES' {
                $env:METASYS_EXPIRES | Should -Be $loginResponse.expires
            }

            It 'Should set $env:METASYS_HOST' {
                $env:METASYS_HOST | Should -Be $script:metasysHost
            }

            It 'Should return nothing' {
                $script:response | Should -BeNullOrEmpty
            }
        }

    }

    Describe "When secret vault is used but not configured" {

    }

    Describe "When secret vault is used and has only one set of credentials for host" {
        Context "When no parameters are passed" {

            BeforeAll {
                $mockConsole = [MockConsole]::new()
                Mock Read-Host -ModuleName MetasysRestClient {
                    $mockConsole.ReadHost($Prompt)
                }

                Mock Invoke-RestMethod -ModuleName MetasysRestClient {
                    CreateLoginResponse
                }

                Mock Get-SavedMetasysUsers -ModuleName MetasysRestClient {
                    , [PSCustomObject]@{
                        UserName = $mockConsole.GetUserName()
                    }
                } -ParameterFilter {
                    $SiteHost -eq $mockConsole.GetMetasysHost()
                }

                Mock Get-SavedMetasysPassword -ModuleName MetasysRestClient {
                    $mockConsole.GetPassword()

                } -ParameterFilter {
                    $SiteHost -eq $mockConsole.GetMetasysHost() -and $UserName -eq $mockConsole.GetUserName()
                }

                Connect-MetasysAccount
            }

            It "Prompts for input exactly 1 time and that is for Metasys Host" {

                Should -Invoke Read-Host -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context

                Should -Invoke Read-Host -ModuleName MetasysRestClient -Scope Context -ParameterFilter {
                    $Prompt -eq [MockConsole]::MetasysHostPrompt
                }
            }

            It "Invokes Invoke-MetasysMethod with correct username and password in the body" {
                $expectedBody = @{
                    username = $mockConsole.GetUserName();
                    password = $mockConsole.GetPasswordAsPlainText();
                } | ConvertTo-Json -Compress
                Should -Invoke Invoke-RestMethod -ModuleName MetasysRestClient -ParameterFilter {
                    ($Body | ConvertFrom-Json | ConvertTo-Json -Compress) -eq $expectedBody
                } -Scope Context
            }



        }
    }

    Describe "Version Handling" {

        BeforeAll {
            Clear-MetasysEnvVariables
            Mock Read-Host -ModuleName MetasysRestClient {
                if ($AsSecureString) {
                    "password" | ConvertTo-SecureString -AsPlainText
                }
                else {
                    "hostname"
                }
            }
        }

        AfterAll {
            Clear-MetasysEnvVariables
        }

        Context "When a valid version is specified" {

            BeforeAll {
                $version = 3
            }

            It "Should be used in the Uri" {

                Mock Invoke-RestMethod -ModuleName MetasysRestClient {
                    CreateLoginResponse
                }

                Connect-MetasysAccount -Version $version

                Should -Invoke Invoke-RestMethod -ModuleName MetasysRestClient -Times 1 -Exactly -ParameterFilter {
                    $Uri.ToString() -eq "https://hostname/api/v$version/login"
                } -Scope Context
            }

            It 'Should be saved to $env:Version' {
                $env:METASYS_VERSION | Should -Be $version
            }
        }

        Context "When an invalid version is specified" {
            It "Should throw an exception for version v<version>" -ForEach @(
                @{ Version = 1 }
                @{ Version = 0 }
                @{ Version = 5 }
            ) {

                { Connect-MetasysAccount -Version $version } | Should -Throw -ExceptionType  System.Management.Automation.ParameterBindingException
            }
        }

    }
}
