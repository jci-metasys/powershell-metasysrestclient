<#
Tests for ConnectMetasys

[ ] If Vault is not specified, don't use vault
[ ] If Host is not specified, prompt
[ ] If UserName is not specified, and unique username for host not found in vault, prompt
[ ] If Password is not specified, and password for host/user not found in value, prompt
[ ] If Version is not specified, default to latest

[ ] Expect Invoke-RestMethod https://$host/api/v$version/api/log -Method Post -Body '{ "usernaem": "$username", "password": "$passwordPlainText"}

#>

<#

Combinations

#>

BeforeAll {
    $mod = Import-Module -Name ./ -Force -PassThru

    . ./MockConsole.ps1

    Set-Variable -Name LatestVersion -Value (Get-MetasysLatestVersion) -Option Constant

    function CreateLoginResponse {
        param(
            [string]$accessToken = "test token",
            [DateTimeOffset]$expires = [DateTimeOffset]::UtcNow
        )
        @{
            accessToken = $accessToken;
            expires     = $expires
        }
    }
}

Describe "Connect-Metasys" -Tag "Unit" {
    Describe "When Secret Vault does not have the credentials" {
        Context "No parameters supplied and preferences for version and skip check not set" {
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
                Mock Set-SavedMetasysPassword -ModuleName MetasysRestClient
                Mock Get-MetasysDefaultApiVersion -ModuleName MetasysRestClient

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
                $env:METASYS_EXPIRES | Should -Be ($loginResponse.expires.ToString("o"))
            }

            It 'Should set $env:METASYS_HOST' {
                $env:METASYS_HOST | Should -Be $mockConsole.GetMetasysHost()
            }

            It 'Should return nothing' {
                $script:response | Should -BeNullOrEmpty
            }

            It 'Should save credentials if vault is available' {
                Should -Invoke Set-SavedMetasysPassword -ModuleName MetasysRestClient -ParameterFilter {
                    $SiteHost -eq $mockConsole.GetMetasysHost() -and
                    $UserName -eq $mockConsole.GetUserName() -and
                    (ConvertFrom-SecureString -AsPlainText $Password) -eq $mockConsole.GetPasswordAsPlainText()
                } -Scope Context -Times 1 -Exactly
            }

        }

        Context "No parameters passed, but preferences for version and skip cert check are set" {
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
                Mock Set-SavedMetasysPassword -ModuleName MetasysRestClient

                $oldVersion = "3"

                # So in this test the following two preferences have been set by the user
                Mock Get-MetasysDefaultApiVersion -ModuleName MetasysRestClient {
                    $oldVersion
                }

                Mock Get-MetasysSkipSecureCheckNotSecure -ModuleName MetasysRestClient {
                    $true
                }

                # qualify with $script to avoid unused-vars warnings from PSScriptAnalyzer
                $script:response = Connect-MetasysAccount
            }



            AfterAll {
                Clear-MetasysEnvVariables
            }

            It "Should invoke Invoke-RestMethod with correct version and skip check" {
                $expectedBody = @{
                    username = $mockConsole.GetUserName();
                    password = $mockConsole.GetPasswordAsPlainText();
                } | ConvertTo-Json -Compress

                Should -Invoke Invoke-RestMethod -ModuleName MetasysRestClient -ParameterFilter {
                    $Method -eq 'Post' -and
                    $ContentType -eq 'application/json' -and
                    $Uri.ToString() -eq "https://$($mockConsole.GetMetasysHost())/api/v$oldVersion/login" -and
                    ($Body | ConvertFrom-Json | ConvertTo-Json -Compress) -eq $expectedBody -and
                    $SkipCertificateCheck -eq $true

                } -Times 1 -Exactly -Scope Context
            }

        }

        Context "If SkipCertificateCheck is explicitly set to false" {
            It "Should override a user preference of true" {
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
                Mock Set-SavedMetasysPassword -ModuleName MetasysRestClient

                # So in this test the preference is to skip the cert check,
                Mock Get-MetasysSkipSecureCheckNotSecure -ModuleName MetasysRestClient {
                    $true
                }

                # But we're going to explicitly set skip cert check to false in the command line
                # It should take precedence
                $script:response = Connect-MetasysAccount -SkipCertificateCheck:$false

                Should -Invoke Invoke-RestMethod -ModuleName MetasysRestClient -ParameterFilter {
                    $SkipCertificateCheck -eq $false

                } -Times 1 -Exactly -Scope Context
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
                Mock Get-MetasysDefaultApiVersion -ModuleName MetasysRestClient

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
                $env:METASYS_EXPIRES | Should -Be ($loginResponse.expires.ToString("o"))
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
                if ($Prompt -eq "Metasys Host") {
                    "hostname"
                }
                else {
                    "password" | ConvertTo-SecureString -AsPlainText
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

    }

    Describe "Error Processing" {
        Context "When the request throws an exception" {
            It "Should stop processing immediately to avoid additional errors" {


                Mock Invoke-RestMethod -ModuleName MetasysRestClient {
                    throw [System.Net.Http.HttpRequestException]::new()
                }

                Mock Write-Information -ModuleName MetasysRestClient

                {
                    Connect-MetasysAccount -h oas -u user -p (password | ConvertTo-SecureString -AsPlainText)
                } | Should -Throw

                Should -Invoke Write-Information -ModuleName MetasysRestClient -Exactly -Times 0 -ParameterFilter {
                    $MessageData -match "Login was successful.*"
                }
            }
        }
    }
}
