Set-StrictMode -Version 3

<#

Invoke-MetasysMethod spec

# Regarding Token

## Fresh Terminal (no env vars set)

- Call Connect-MetasysAccount with no parameters, if successful, make the call


## Token set and not expired and not expiring

- An attempt to make the call should be made

## Token set but expiring in < 5 minutes

- An attempt to refresh the token should be made, if successful env vars updated, if not successful a warning (or info?) should be written
- Regardless and attempt to make the call should be made

## Token expired

- If password can be found in secret management, an attempt to re-connect should be made with last site host, username and stored password, then call should be attempted
- If password cannot be found then call Connect-MetasysAccount with last site host and last username


# Regarding Path

- If full URL given and no conflicting version, make the call
- If full URL given with confliction version, error
- If relative URL given, construct full URL

# Regarding Refresh Token attempt

- Use saved version

# Regarding First Connect

- Use version specified (or defaulted to)

# Regarding Re-connect

- Use saved version

#>

BeforeAll {
    $mod = Import-Module -Name ./ -Force -PassThru

    . ./MockConsole.ps1

    Set-Variable -Name LatestVersion -Value 4 -Option Constant

    function CreateLoginResponse {
        param(
            [string]$accessToken = "test token",
            [DateTime]$expires = [DateTime]::UtcNow
        )
        @{
            accessToken = $accessToken;
            expires     = $expires
        }
    }
    <# We can't control how headers are sorted so to compare expect/actual response
    we'll always expect sorted headers, and we'll sort the actual headers.
    #>

    # Expect the status line, then 0 or more header lines, then a blank line and theen
    # the body
    function sortHeaders {
        param(
            [Parameter(ValueFromPipeline = $true)]
            [string]$InputString
        )

        # make this split on new line work with either line ending \r or \r\n
        #https://stackoverflow.com/a/42216677/697188
        $lines = $InputString -split '\r?\n'

        $blankLineIndex = [Array]::IndexOf($lines, "")
        $headerLines = ($lines[1..($blankLineIndex - 1)] | Sort-Object) -join ([Environment]::NewLine)
        $theRest = ($lines[$blankLineIndex..($lines.Length - 1)]) -join ([Environment]::NewLine)

        $lines[0] + ([Environment]::NewLine) + $headerLines + ([Environment]::NewLine) + $theRest
    }
}

Describe "Invoke-MetasysMethod" -Tag Unit {

    Describe "When Token Stored in Env Vars and Token is not expired, and SiteHost stored in env vars" {
        BeforeAll {
            Clear-MetasysEnvVariables
            $env:METASYS_ACCESS_TOKEN = (ConvertTo-SecureString -AsPlainText "This is the token") | ConvertFrom-SecureString
            $env:METASYS_EXPIRES = ([DateTimeOffset]::UtcNow + [TimeSpan]::FromMinutes(30)).ToString("o")
            $env:METASYS_HOST = "oas12"
            $env:METASYS_VERSION = $LatestVersion
        }

        Context "No parameters supplied" {
            BeforeAll {

                $mockConsole = [MockConsole]::new()
                Mock Read-Host -ModuleName MetasysRestClient {
                    $mockConsole.ReadHost($Prompt)
                }

                Mock Invoke-WebRequest -ModuleName MetasysRestClient {

                }

                Invoke-MetasysMethod
            }

            It "Should prompt for Path" {
                Should -Invoke Read-Host -ModuleName MetasysRestClient -ParameterFilter {
                    $Prompt -eq [MockConsole]::PathPrompt
                } -Exactly -Times 1 -Scope Context
            }

            It "Should Invoke Operation" {
                Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient  -ParameterFilter {
                    $Uri.ToString() -eq "https://$($env:METASYS_HOST)/api/v$LatestVersion" + "$($mockConsole.GetResponse([MockConsole]::PathPrompt))"
                } -Exactly -Times 1 -Scope Context

            }
        }

        Context "Multiple Bodies passed in pipeline with absolutel uri version mismatch with version" {

            BeforeAll {

                Mock Write-Error -ModuleName MetasysRestClient

                Mock Invoke-WebRequest -ModuleName MetasysRestClient

                @( "body1", "body2" ) | Invoke-MetasysMethod -Method Post https://oas12/api/v4/objects -Version 3

            }

            It "Should exit BEGIN block and not enter PROCESS block" {
                Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -Exactly -Times 0 -Scope Context
            }

        }



    }





    Describe "Reconnecting Expired Connection" {

        BeforeAll {
            Clear-MetasysEnvVariables
            $env:METASYS_EXPIRES = ([DateTimeOffset]::UtcNow - [TimeSpan]::FromMinutes(5)).ToString("o")
            $env:METASYS_ACCESS_TOKEN = "secure token" | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
            $env:METASYS_VERSION = $LatestVersion
            $env:METASYS_HOST = "oas12"
            $env:METASYS_USER_NAME = "api"
        }

        Context "An operation is invoked, but session is expired" {
            BeforeAll {

                Mock Invoke-WebRequest -ModuleName MetasysRestClient
                Mock Connect-MetasysAccount -ModuleName MetasysRestClient
                Mock Get-SavedMetasysPassword -ModuleName MetasysRestClient {
                    ConvertTo-SecureString -String "ThePassword" -AsPlainText
                }
                Invoke-MetasysMethod /objects
            }

            It "Should attempt to reconnect" {
                Should -Invoke Connect-MetasysAccount -ModuleName MetasysRestClient -ParameterFilter {
                    $MetasysHost -eq $env:METASYS_HOST -and
                    $UserName -eq $env:METASYS_USER_NAME -and
                    $Version -eq $env:METASYS_VERSION -and
                    $SkipCertificateCheck -eq $False
                } -Scope Context -Times 1 -Exactly
            }

            It "Should call the operation" {
                Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -Scope Context -Times 1 -Exactly
            }
        }

    }

    Describe "Refreshing Token" {

    }


    Describe "PipeLine Processing" {
        Context "When no connection previously made" {
            BeforeAll {
                Clear-MetasysEnvVariables
            }


            Context "Single body passed in" {
                It "Should exit BEGIN block and not enter PROCESS block" {
                    Mock Write-Error -ModuleName MetasysRestClient
                    Mock Invoke-WebRequest -ModuleName MetasysRestClient
                    Invoke-MetasysMethod /objects -Method Post -Body "body" | Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -Exactly -Times  0

                }
            }
            Context "Multiple bodies passed in" {
                It "Should exit BEGIN block and not enter PROCESS block" {

                    Mock Write-Error -ModuleName MetasysRestClient
                    Mock Invoke-WebRequest -ModuleName MetasysRestClient
                    @("body1", "body2") | Invoke-MetasysMethod /objects -Method Post | Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -Exactly -Times  0
                }

            }
        }

        Context "When session expired" {

            BeforeAll {
                Clear-MetasysEnvVariables
                $env:METASYS_EXPIRES = ([DateTimeOffset]::UtcNow - [TimeSpan]::FromMinutes(5)).ToString("o")
                $env:METASYS_ACCESS_TOKEN = "secure token" | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
                $env:METASYS_VERSION = $LatestVersion
            }

            Context "Single body passed in and reconnection fails" {
                It "Should exit BEGIN block and not enter PROCESS block" {
                    Mock Write-Error -ModuleName MetasysRestClient
                    Mock Connect-MetasysAccount -ModuleName MetasysRestClient {
                        throw "error"
                    }
                    Invoke-MetasysMethod /objects -Method Post -Body "body" | Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -Exactly -Times  0

                }
            }

            Context "Multiple bodies passed in, and reconnecting fails" {
                It "Should exit BEGIN block and not enter PROCESS block" {

                    Mock Write-Error -ModuleName MetasysRestClient
                    Mock Connect-MetasysAccount -ModuleName MetasysRestClient {
                        throw "error"
                    }

                    @("body1", "body2") | Invoke-MetasysMethod /objects -Method Post | Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -Exactly -Times  0

                }
            }
        }

        Context "When session nearing expiration" {
            BeforeAll {
                Clear-MetasysEnvVariables
                $env:METASYS_EXPIRES = ([DateTimeOffset]::UtcNow + [TimeSpan]::FromMinutes(2)).ToString("o")
                $env:METASYS_ACCESS_TOKEN = "secure token" | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
                $env:METASYS_VERSION = $LatestVersion
                $env:METASYS_HOST = "oas12"
            }

            Context "Multiple bodies passed in and refresh token fails" {
                It "Should exit BEGIN block and not enter PROCESS block" {

                    Mock Invoke-WebRequest -ModuleName MetasysRestClient
                    Mock Invoke-RestMethod -ModuleName MetasysRestClient {
                        throw "error"
                    }
                    @("body1", "body2") | Invoke-MetasysMethod /objects -Method Post | Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -Exactly -Times  0

                }
            }
        }
    }

    Describe 'When -IncludeResponseHeaders with success response' {

        BeforeAll {
            Clear-MetasysEnvVariables
            $env:METASYS_EXPIRES = ([DateTimeOffset]::UtcNow + [TimeSpan]::FromMinutes(30)).ToString("o")
            $env:METASYS_ACCESS_TOKEN = "secure token" | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
            $env:METASYS_VERSION = $LatestVersion
            $env:METASYS_HOST = "oas12"
        }

        It "Should display response headers and then the response body" {


            $response = @{
                StatusCode        = 200;
                StatusDescription = "OK"
                Headers           = @{
                    Header1        = "This is header 1";
                    Header2        = "Header 2";
                    "Content-Type" = "application/json"
                };
                Content           = 123, 10, 32, 32, 34, 105, 116, 101, 109, 34, 58, 32, 123, 10, 32, 32, 32, 32, 34, 112, 114, 101, 115, 101, 110, 116, 86, 97, 108, 117, 101, 34, 58, 32, 55, 50, 46, 53, 10, 32, 32, 125, 10, 125
            }
            Mock Invoke-WebRequest -ModuleName MetasysRestClient {
                # Mocking Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject
                $response
            }
            $expectedString = @"
200 (OK)
Content-Type: application/json
Header1: This is header 1
Header2: Header 2


"@
            $expectedString += [System.Text.Encoding]::UTF8.GetString($response.Content)
            $actual = Invoke-MetasysMethod /anything -IncludeResponseHeaders
            $actual | Should -Be  $expectedString
        }
    }


    Describe 'When -IncludeResponseHeaders with response error' {
        BeforeAll {
            Clear-MetasysEnvVariables
            $env:METASYS_EXPIRES = ([DateTimeOffset]::UtcNow + [TimeSpan]::FromMinutes(30)).ToString("o")
            $env:METASYS_ACCESS_TOKEN = "secure token" | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
            $env:METASYS_VERSION = $LatestVersion
            $env:METASYS_HOST = "oas12"
        }

        It "Should display all headers and response body" {
            Mock Invoke-WebRequest -ModuleName MetasysRestClient {
                # Mocking Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject
                $response = @{
                    StatusCode        = 400;
                    StatusDescription = "Bad Request"
                    Headers           = @{
                        Header1        = "This is header 1";
                        Header2        = "Header 2";
                        "Content-Type" = "application/json"
                    };
                    Content           = 34, 104, 101, 108, 108, 111, 34
                }
                $response
            }
            $expectedString = @"
400 (Bad Request)
Content-Type: application/json
Header1: This is header 1
Header2: Header 2

"hello"
"@

            # Since header order isn't important or guaranteed we'll sort the headers before checking

            $actual = Invoke-MetasysMethod /anything -IncludeResponseHeaders | sortHeaders
            $actual | Should -Be  $expectedString
        }
    }

}



