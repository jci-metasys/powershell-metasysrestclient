Set-StrictMode -Version 3

# Load at script body level so InModuleScope can find the local version during discovery
Remove-Module MetasysRestClient -ErrorAction SilentlyContinue
Import-Module -Name ./ -Force

Describe "MetasysEnvVars.setLast" {

    InModuleScope MetasysRestClient {

        BeforeEach {
            # Start each test with a clean directory state
            $dir = [MetasysEnvVars]::getLastResponseDir()
            if ([System.IO.Directory]::Exists($dir)) {
                Remove-Item -Path $dir -Recurse -Force
            }
            $env:METASYS_LAST_RESPONSE_PATH = $null
        }

        AfterAll {
            $dir = [MetasysEnvVars]::getLastResponseDir()
            if ([System.IO.Directory]::Exists($dir)) {
                Remove-Item -Path $dir -Recurse -Force
            }
            $env:METASYS_LAST_RESPONSE_PATH = $null
        }

        It "Creates the directory if it does not exist" {
            [MetasysEnvVars]::setLast('{}')
            $dir = [MetasysEnvVars]::getLastResponseDir()
            [System.IO.Directory]::Exists($dir) | Should -BeTrue
        }

        It "Writes content to the fixed path" {
            [MetasysEnvVars]::setLast('{"value":1}')
            $path = [System.IO.Path]::Combine([MetasysEnvVars]::getLastResponseDir(), 'last-response')
            Get-Content -Path $path -Raw | Should -Be '{"value":1}'
        }

        It "Sets METASYS_LAST_RESPONSE_PATH to the fixed path" {
            [MetasysEnvVars]::setLast('{}')
            $expected = [System.IO.Path]::Combine([MetasysEnvVars]::getLastResponseDir(), 'last-response')
            $env:METASYS_LAST_RESPONSE_PATH | Should -Be $expected
        }

        It "Removes leftover files from previous sessions before writing" {
            $dir = [MetasysEnvVars]::getLastResponseDir()
            [System.IO.Directory]::CreateDirectory($dir) | Out-Null
            # Simulate orphaned files from old sessions
            Set-Content -Path ([System.IO.Path]::Combine($dir, 'old-file-1')) -Value 'stale'
            Set-Content -Path ([System.IO.Path]::Combine($dir, 'old-file-2')) -Value 'stale'

            [MetasysEnvVars]::setLast('{"fresh":true}')

            $files = @(Get-ChildItem -Path $dir -File)
            $files | Should -HaveCount 1
            $files[0].Name | Should -Be 'last-response'
        }

        It "getLast returns the content written by setLast" {
            [MetasysEnvVars]::setLast('{"answer":42}')
            [MetasysEnvVars]::getLast() | Should -BeLike '*"answer":42*'
        }
    }
}

Describe "MetasysEnvVars.clear" {

    It "Clears METASYS_LAST_RESPONSE_PATH" {
        InModuleScope MetasysRestClient {
            $env:METASYS_LAST_RESPONSE_PATH = 'some/path'
            [MetasysEnvVars]::clear()
            $env:METASYS_LAST_RESPONSE_PATH | Should -BeNullOrEmpty
        }
    }
}
