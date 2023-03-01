BeforeAll {
    Import-Module -Force -Name ./

    $script:secretManagementInstalled = Get-Module -ListAvailable Microsoft.PowerShell.SecretManagement
}

# Since all of the password management functions depend on secret management it's useful
# to use the state of secret management as our top level Describe/Contexts rather than starting
# with the module names. That was each function can be tested within the shared context, rather
# than duplciating all of the contexts for each function.

Describe "Password Management When No Vaults Registered" {
    Context "Get-SavedMetasysUsers" {
        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Get-SavedMetasysUsers
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }
    }

    Context "Get-SavedMetasysPassword" {

        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Get-SavedMetasysPassword -SiteHost anything -UserName anything
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }
    }

    Context "Set-SavedMetasysPassword" {

        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Set-SavedMetasysPassword -SiteHost anything -UserName anything -Password (ConvertTo-SecureString anything -AsPlainText)
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }

    }

    Context "Remove-SavedMetasysPassword" {
        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Remove-SavedMetasysPassword -SiteHost anything -UserName anything
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }
    }
}



Describe "Password Management When Vault Registered but the module for that vault is not installed" {
    Context "Get-SavedMetasysUsers" {
        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient {
                    @{ ModuleName = "DoesNotExist" }
                }
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Get-SavedMetasysUsers
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }
    }

    Context "Get-SavedMetasysPassword" {

        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Get-SavedMetasysPassword -SiteHost anything -UserName anything
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }
    }

    Context "Set-SavedMetasysPassword" {

        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Set-SavedMetasysPassword -SiteHost anything -UserName anything -Password (ConvertTo-SecureString anything -AsPlainText)
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }

    }

    Context "Remove-SavedMetasysPassword" {
        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Remove-SavedMetasysPassword -SiteHost anything -UserName anything
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }
    }
}




Describe "Password Management When a Single Vault is registered" {
    Context "Get-SavedMetasysUsers" {
        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient {
                    @{ ModuleName = "DoesNotExist" }
                }
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Get-SavedMetasysUsers
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }
    }

    Context "Get-SavedMetasysPassword" {

        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Get-SavedMetasysPassword -SiteHost anything -UserName anything
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }
    }

    Context "Set-SavedMetasysPassword" {

        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Set-SavedMetasysPassword -SiteHost anything -UserName anything -Password (ConvertTo-SecureString anything -AsPlainText)
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }

    }

    Context "Remove-SavedMetasysPassword" {
        BeforeAll {
            if ($script:secretManagementInstalled) {
                Mock Get-SecretVault -ModuleName MetasysRestClient
            }
            Mock Write-Information -ModuleName MetasysRestClient
            $result = Remove-SavedMetasysPassword -SiteHost anything -UserName anything
            if (!$result) {
                $returnedNothing = $true
            }
        }

        It "Should return nothing" {
            $returnedNothing | Should -BeTrue
        }

        It "Should write an information message" {
            Should -Invoke Write-Information -ModuleName MetasysRestClient -Times 1 -Exactly -Scope Context
        }
    }
}



# Describe "Get-SavedMetasysUsers" {
#     Context "When no vaults registered" {

#         It "Should return nothing" {
#             Mock Get-SecretVault -ModuleName MetasysRestClient
#             Get-SavedMetasysUsers | Should -Be $null
#         }
#     }

#     Context "When only one vault is registered" {

#         Context "When no SiteHost specified, no metasys users saved, and no other secrets saved" {
#             It "Should return nothing" {
#                 Mock Get-SecretVault -ModuleName -MetasysRestClient {
#                     # just return something with a ModuleName, doesn't matter what
#                     @{ ModuleName = "Some Module" }
#                 }
#                 Mock Import-Module -ModuleName MetasysRestClient {
#                     # just return something, doesn't matter what
#                     $true
#                 }
#             }
#         }

#         Context "When no SiteHost specified, no metasys users saved, but other secrets saved" {
#             It "Should return nothing" {
#                 Mock Get-SecretVault -ModuleName -MetasysRestClient {
#                     # just return something with a ModuleName, doesn't matter what
#                     @{ ModuleName = "Some Module" }
#                 }
#                 Mock Import-Module -ModuleName MetasysRestClient {
#                     # just return something, doesn't matter what
#                     $true
#                 }
#             }
#         }

#         Context "When no SiteHost specified, some metasys users saved, and other secrets saved" {
#             It "Should return just metasys users" {
#                 Mock Get-SecretVault -ModuleName -MetasysRestClient {
#                     # just return something with a ModuleName, doesn't matter what
#                     @{ ModuleName = "Some Module" }
#                 }
#                 Mock Import-Module -ModuleName MetasysRestClient {
#                     # just return something, doesn't matter what
#                     $true
#                 }
#             }
#         }
#     }

#     Context "When multiple vaults are regsitered" {

#     }
# }
