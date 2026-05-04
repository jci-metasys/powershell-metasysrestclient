Set-StrictMode -Version 3

BeforeAll {
    $mod = Import-Module -Name ./ -Force -PassThru

    Set-Variable -Name LatestVersion -Value (Get-MetasysLatestVersion) -Option Constant

    function CreateReadAttributeResponse {
        param(
            [string]$AttributeId,
            [object]$Value,
            [string]$MetasysType = "float",
            [hashtable]$Condition = @{}
        )
        $conditionJson = $Condition | ConvertTo-Json -Compress
        @"
{
    "item": {
        "$AttributeId": $($Value | ConvertTo-Json)
    },
    "condition": $conditionJson,
    "schema": {
        "type": "object",
        "properties": {
            "$AttributeId": {
                "metasysType": "$MetasysType",
                "type": "number"
            }
        }
    }
}
"@
    }

    function CreateWebResponse {
        param(
            [string]$Body,
            [int]$StatusCode = 200,
            [string]$StatusDescription = "OK"
        )
        $response = [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject]::new()
        $headers = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.IEnumerable[string]]]::new()
        $headers["Content-Type"] = [string[]]@("application/json; charset=utf-8")
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
        $response.GetType().GetField("_content", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($response, $bodyBytes)
        $response.GetType().GetField("_statusCode", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($response, [System.Net.HttpStatusCode]$StatusCode)
        $response.GetType().GetField("_statusDescription", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($response, $StatusDescription)
        $response.GetType().GetField("_headers", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($response, $headers)
        $response
    }

    function SetupConnectedSession {
        Clear-MetasysEnvVariables
        $env:METASYS_ACCESS_TOKEN = (ConvertTo-SecureString -AsPlainText "test-token") | ConvertFrom-SecureString
        $env:METASYS_EXPIRES = ([DateTimeOffset]::UtcNow + [TimeSpan]::FromMinutes(30)).ToString("o")
        $env:METASYS_HOST = "oas12"
        $env:METASYS_VERSION = $LatestVersion
    }
}

Describe "Invoke-MetasysReadAttribute" -Tag Unit {

    Describe "Read by ObjectId" {

        BeforeAll {
            SetupConnectedSession
        }

        Context "Successful read of a float attribute" {

            BeforeAll {
                $objectId = "ba1a703a-1e96-54ae-9ae6-9590a55c2e4a"
                $attributeId = "presentValue"
                $expectedValue = 68.5
                $responseBody = CreateReadAttributeResponse -AttributeId $attributeId -Value $expectedValue -MetasysType "float"

                Mock Invoke-WebRequest -ModuleName MetasysRestClient {
                    [PSCustomObject]@{
                        Content           = $responseBody
                        StatusCode        = 200
                        StatusDescription = "OK"
                        Headers           = @{ "Content-Type" = "application/json" }
                    }
                }

                $script:result = Invoke-MetasysReadAttribute -ObjectId $objectId -AttributeId $attributeId
            }

            It "Should call the correct API endpoint" {
                Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -ParameterFilter {
                    $Uri.ToString() -like "*/objects/$objectId/attributes/$attributeId*includeSchema=true*"
                } -Exactly -Times 1 -Scope Context
            }

            It "Should return the attribute value" {
                $script:result | Should -Be $expectedValue
            }

            It "Should use GET method" {
                Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -ParameterFilter {
                    $Method -eq "Get"
                } -Exactly -Times 1 -Scope Context
            }
        }

        Context "Successful read of a string attribute" {

            BeforeAll {
                $objectId = "ba1a703a-1e96-54ae-9ae6-9590a55c2e4a"
                $attributeId = "name"
                $expectedValue = "AHU-1"
                $responseBody = CreateReadAttributeResponse -AttributeId $attributeId -Value $expectedValue -MetasysType "string"

                Mock Invoke-WebRequest -ModuleName MetasysRestClient {
                    [PSCustomObject]@{
                        Content           = $responseBody
                        StatusCode        = 200
                        StatusDescription = "OK"
                        Headers           = @{ "Content-Type" = "application/json" }
                    }
                }

                $script:result = Invoke-MetasysReadAttribute -ObjectId $objectId -AttributeId $attributeId
            }

            It "Should return the string value" {
                $script:result | Should -Be $expectedValue
            }
        }

        Context "Attribute has non-normal conditions" {

            BeforeAll {
                $objectId = "ba1a703a-1e96-54ae-9ae6-9590a55c2e4a"
                $attributeId = "presentValue"
                $condition = @{
                    presentValue = @{
                        reliability = "reliabilityEnumSet.noSensorConnected"
                    }
                }
                $responseBody = CreateReadAttributeResponse -AttributeId $attributeId -Value 0.0 -Condition $condition

                Mock Invoke-WebRequest -ModuleName MetasysRestClient {
                    [PSCustomObject]@{
                        Content           = $responseBody
                        StatusCode        = 200
                        StatusDescription = "OK"
                        Headers           = @{ "Content-Type" = "application/json" }
                    }
                }

                Mock Write-Warning -ModuleName MetasysRestClient

                Invoke-MetasysReadAttribute -ObjectId $objectId -AttributeId $attributeId
            }

            It "Should write a warning about non-normal conditions" {
                Should -Invoke Write-Warning -ModuleName MetasysRestClient -ParameterFilter {
                    $Message -like "*$attributeId*non-normal conditions*"
                } -Exactly -Times 1 -Scope Context
            }
        }
    }

    Describe "Read by ItemReference" {

        BeforeAll {
            SetupConnectedSession
        }

        Context "ObjectId found in cache (no API call for ID lookup)" {

            BeforeAll {
                $itemReference = "site:device.AHU-1"
                $cachedObjectId = "ba1a703a-1e96-54ae-9ae6-9590a55c2e4a"
                $attributeId = "presentValue"
                $expectedValue = 72.0
                $responseBody = CreateReadAttributeResponse -AttributeId $attributeId -Value $expectedValue

                Mock GetObjectId -ModuleName MetasysRestClient { $cachedObjectId }

                Mock Invoke-WebRequest -ModuleName MetasysRestClient {
                    [PSCustomObject]@{
                        Content           = $responseBody
                        StatusCode        = 200
                        StatusDescription = "OK"
                        Headers           = @{ "Content-Type" = "application/json" }
                    }
                }

                $script:result = Invoke-MetasysReadAttribute -ItemReference $itemReference -AttributeId $attributeId
            }

            It "Should look up object ID from cache" {
                Should -Invoke GetObjectId -ModuleName MetasysRestClient -ParameterFilter {
                    $ItemReference -eq "site:device.AHU-1"
                } -Exactly -Times 1 -Scope Context
            }

            It "Should not call identifiers endpoint" {
                Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -ParameterFilter {
                    $Uri.ToString() -like "*identifiers*"
                } -Exactly -Times 0 -Scope Context
            }

            It "Should call attribute endpoint with cached ObjectId" {
                Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -ParameterFilter {
                    $Uri.ToString() -like "*/objects/$cachedObjectId/attributes/$attributeId*"
                } -Exactly -Times 1 -Scope Context
            }

            It "Should return the attribute value" {
                $script:result | Should -Be $expectedValue
            }
        }

        Context "ObjectId not in cache - resolved via API and then cached" {

            BeforeAll {
                $itemReference = "site:device.AHU-1"
                $resolvedObjectId = "cc2b814a-2f07-65bf-0bf7-a661c5bd3f5b"
                $attributeId = "presentValue"
                $expectedValue = 55.0
                $responseBody = CreateReadAttributeResponse -AttributeId $attributeId -Value $expectedValue

                Mock GetObjectId -ModuleName MetasysRestClient { $null }
                Mock CacheObjectId -ModuleName MetasysRestClient

                Mock Invoke-WebRequest -ModuleName MetasysRestClient {
                    param($Uri)
                    if ($Uri.ToString() -like "*identifiers*") {
                        [PSCustomObject]@{
                            Content           = "`"$resolvedObjectId`""
                            StatusCode        = 200
                            StatusDescription = "OK"
                            Headers           = @{ "Content-Type" = "application/json" }
                        }
                    }
                    else {
                        [PSCustomObject]@{
                            Content           = $responseBody
                            StatusCode        = 200
                            StatusDescription = "OK"
                            Headers           = @{ "Content-Type" = "application/json" }
                        }
                    }
                }

                $script:result = Invoke-MetasysReadAttribute -ItemReference $itemReference -AttributeId $attributeId
            }

            It "Should call identifiers endpoint to resolve the ItemReference" {
                Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -ParameterFilter {
                    $Uri.ToString() -like "*identifiers*fqr=$itemReference*"
                } -Exactly -Times 1 -Scope Context
            }

            It "Should cache the resolved ObjectId" {
                Should -Invoke CacheObjectId -ModuleName MetasysRestClient -ParameterFilter {
                    $ItemReference -eq $itemReference -and $ObjectId -eq $resolvedObjectId
                } -Exactly -Times 1 -Scope Context
            }

            It "Should return the attribute value" {
                $script:result | Should -Be $expectedValue
            }
        }

        Context "ItemReference not found" {

            BeforeAll {
                # Clear the cache to ensure GetObjectId returns null without needing a mock.
                # This avoids any stale cache state on the developer's machine.
                Remove-MetasysCache -MetasysHost "oas12"

                # The real identifiers API returns a JSON object (not a bare string) when
                # the reference can't be resolved. Return a non-string body so that
                # Invoke-MetasysMethod returns a Hashtable, which fails the
                # non-string guard in Invoke-MetasysReadAttribute.
                Mock Invoke-WebRequest -ModuleName MetasysRestClient {
                    [PSCustomObject]@{
                        Content           = '{"httpCode":400,"message":"Object not found"}'
                        StatusCode        = 400
                        StatusDescription = "Bad Request"
                        Headers           = @{ "Content-Type" = "application/json" }
                    }
                }

                Invoke-MetasysReadAttribute -ItemReference "site:device.DoesNotExist" -AttributeId "presentValue" `
                    -ErrorAction SilentlyContinue -ErrorVariable script:capturedErrors
            }

            It "Should report an error that the reference was not found" {
                $script:capturedErrors[0].Exception.Message | Should -BeLike "*not found*"
            }

            It "Should not attempt to read the attribute" {
                Should -Invoke Invoke-WebRequest -ModuleName MetasysRestClient -ParameterFilter {
                    $Uri.ToString() -like "*/attributes/*"
                } -Exactly -Times 0 -Scope Context
            }
        }
    }

    Describe "Alias" {

        It "Should have an alias 'ira'" {
            (Get-Alias -Name ira).Definition | Should -Be 'Invoke-MetasysReadAttribute'
        }
    }
}
