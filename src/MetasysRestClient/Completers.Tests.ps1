Set-StrictMode -Version 3

BeforeAll {
    Import-Module -Name ./ -Force

    # Helper: write a cache file for a given host with the provided hashtable of
    # ItemReference -> ObjectId entries.
    function WriteCacheFile {
        param(
            [string]$MetasysHost,
            [hashtable]$Entries
        )
        $cacheDir = [System.IO.Path]::Combine($env:HOME, "Library", "Caches", "MetasysRestClient")
        if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir | Out-Null }
        $filePath = [System.IO.Path]::Combine($cacheDir, "$MetasysHost-cachedObjectIds.json")
        [System.IO.File]::WriteAllText($filePath, ($Entries | ConvertTo-Json))
    }
}

Describe "Tab completion" {

    BeforeAll {
        $script:testHost = "completers-test-host"
        $env:METASYS_HOST = $script:testHost

        WriteCacheFile -MetasysHost $script:testHost -Entries @{
            "site:device.AHU-1"      = "ba1a703a-1e96-54ae-9ae6-9590a55c2e4a"
            "site:device.AHU-2"      = "cc2b814a-2f07-65bf-0bf7-a661c5bd3f5b"
            "site:other.VAV-1"       = "dd3c925b-3018-76c0-1c08-b772d6ce406c"
            "site:device.With Space" = "ee4da36c-4129-87d1-2d19-c883e7df517d"
        }
    }

    AfterAll {
        InModuleScope MetasysRestClient { Remove-MetasysCache -MetasysHost $env:METASYS_HOST }
    }

    Describe "Get-MetasysCachedItemReferences" {

        It "Returns all references when wordToComplete is empty" {
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedItemReferences $null $null "" $null $null
            }
            $results.Count | Should -Be 4
        }

        It "Filters references by wordToComplete" {
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedItemReferences $null $null "AHU" $null $null
            }
            $results.Count | Should -Be 2
            $results.CompletionText | Should -Contain '"site:device.AHU-1"'
            $results.CompletionText | Should -Contain '"site:device.AHU-2"'
        }

        It "Excludes references that do not match wordToComplete" {
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedItemReferences $null $null "VAV" $null $null
            }
            $results.Count | Should -Be 1
            $results[0].CompletionText | Should -Be '"site:other.VAV-1"'
        }

        It "Wraps all results in quotes when any reference contains a space" {
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedItemReferences $null $null "" $null $null
            }
            $results | ForEach-Object {
                $_.CompletionText | Should -Match '^".*"$'
            }
        }

        It "Does not quote results when no reference contains a space" {
            WriteCacheFile -MetasysHost $script:testHost -Entries @{
                "site:device.AHU-1" = "ba1a703a-1e96-54ae-9ae6-9590a55c2e4a"
                "site:device.AHU-2" = "cc2b814a-2f07-65bf-0bf7-a661c5bd3f5b"
            }
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedItemReferences $null $null "" $null $null
            }
            $results | ForEach-Object {
                $_.CompletionText | Should -Not -Match '^"'
            }
            # Restore full cache for subsequent tests
            WriteCacheFile -MetasysHost $script:testHost -Entries @{
                "site:device.AHU-1"      = "ba1a703a-1e96-54ae-9ae6-9590a55c2e4a"
                "site:device.AHU-2"      = "cc2b814a-2f07-65bf-0bf7-a661c5bd3f5b"
                "site:other.VAV-1"       = "dd3c925b-3018-76c0-1c08-b772d6ce406c"
                "site:device.With Space" = "ee4da36c-4129-87d1-2d19-c883e7df517d"
            }
        }

        It "Returns CompletionResult objects" {
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedItemReferences $null $null "AHU-1" $null $null
            }
            $results[0] | Should -BeOfType [System.Management.Automation.CompletionResult]
        }
    }

    Describe "Get-MetasysCachedObjectIds" {

        It "Returns object IDs matching the prefix" {
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedObjectIds $null $null "ba1a" $null $null
            }
            $results.Count | Should -Be 1
            $results[0].CompletionText | Should -Be "ba1a703a-1e96-54ae-9ae6-9590a55c2e4a"
        }

        It "Includes the item reference in the list item text" {
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedObjectIds $null $null "ba1a" $null $null
            }
            $results[0].ListItemText | Should -BeLike "*site:device.AHU-1*"
        }

        It "Excludes IDs that do not match the prefix" {
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedObjectIds $null $null "zzzzz" $null $null
            }
            $results.Count | Should -Be 0
        }

        It "Returns CompletionResult objects" {
            $results = InModuleScope MetasysRestClient {
                Get-MetasysCachedObjectIds $null $null "ba1a" $null $null
            }
            $results[0] | Should -BeOfType [System.Management.Automation.CompletionResult]
        }
    }

    Describe "Completer registration" {

        It "ItemReference completer is registered for Invoke-MetasysReadAttribute" {
            $completions = [System.Management.Automation.CommandCompletion]::CompleteInput(
                "Invoke-MetasysReadAttribute -ItemReference ", 43, $null
            )
            $completions.CompletionMatches.Count | Should -BeGreaterThan 0
        }

        It "ObjectId completer is registered for Invoke-MetasysReadAttribute" {
            $completions = [System.Management.Automation.CommandCompletion]::CompleteInput(
                "Invoke-MetasysReadAttribute -ObjectId ", 38, $null
            )
            $completions.CompletionMatches.Count | Should -BeGreaterThan 0
        }
    }
}

