###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


Describe "AllToolsUtilities.psm1" {
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'Containers-Toolkit'
        Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\ContainerdTools.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\BuildkitTools.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\NerdctlTools.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\ContainerNetworkTools.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\AllToolsUtilities.psm1" -Force
    }

    AfterAll {
        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\AllToolsUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\ContainerdTools.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\BuildkitTools.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\NerdctlTools.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\ContainerNetworkTools.psm1" -Force -ErrorAction Ignore
    }

    Context "Show-ContainerTools" -Tag "Show-ContainerTools" {
        BeforeAll {
            Mock Get-InstalledVersion -ModuleName 'AllToolsUtilities'
        }

        It "Should list all container tools and their install status" {
            Show-ContainerTools

            @("containerd", "buildkit", "nerdctl") | ForEach-Object {
                Should -Invoke Get-InstalledVersion -ModuleName 'AllToolsUtilities' `
                    -Times 1 -Exactly -Scope It `
                    -ParameterFilter { $Feature -eq $_ }
            }
        }

        It "Should list the latest available version for each tool" {
            Show-ContainerTools -Latest

            @("containerd", "buildkit", "nerdctl") | ForEach-Object {
                Should -Invoke Get-InstalledVersion -ModuleName 'AllToolsUtilities' `
                    -Times 1 -Exactly -Scope It `
                    -ParameterFilter { $Feature -eq $_ -and $Latest -eq $true }
            }
        }
    }

    Context "Install-ContainerTools" -Tag "Install-ContainerTools" {
        BeforeAll {
            Mock Install-Containerd -ModuleName 'AllToolsUtilities'
            Mock Install-Buildkit -ModuleName 'AllToolsUtilities'
            Mock Install-Nerdctl -ModuleName 'AllToolsUtilities'
            Mock Initialize-NatNetwork -ModuleName 'AllToolsUtilities'
        }

        It 'Should not process on implicit request for validation (WhatIfPreference)' {
            Mock Install-ContainerTools -ModuleName "AllToolsUtilities"
            {
                $WhatIfPreference = $true
                Install-ContainerTools
            }
            Should -Invoke -CommandName Install-ContainerTools -ModuleName 'AllToolsUtilities' -Exactly -Times 0 -Scope It
        }

        It 'Should not process on explicit request for validation (-WhatIf)' {
            Mock Install-ContainerTools -ModuleName "AllToolsUtilities"

            { Install-ContainerTools -WhatIf }
            Should -Invoke -CommandName Install-ContainerTools -ModuleName 'AllToolsUtilities' -Exactly -Times 0 -Scope It
        }

        It "Should use defaults" {
            Install-ContainerTools -Confirm:$false

            Should -Invoke Install-Containerd -ModuleName 'AllToolsUtilities' `
                -ParameterFilter {
                $Version -eq 'latest' -and
                $InstallPath -eq "$Env:ProgramFiles\Containerd" -and
                $DownloadPath -eq "$HOME\Downloads" -and
                $Setup -eq $false
            }

            Should -Invoke Install-Buildkit -ModuleName 'AllToolsUtilities' `
                -ParameterFilter {
                $Version -eq 'latest' -and
                $InstallPath -eq "$Env:ProgramFiles\BuildKit" -and
                $DownloadPath -eq "$HOME\Downloads" -and
                $Setup -eq $false
            }

            Should -Invoke Install-Nerdctl -ModuleName 'AllToolsUtilities' `
                -ParameterFilter {
                $Version -eq 'latest' -and
                $InstallPath -eq "$Env:ProgramFiles\nerdctl" -and
                $DownloadPath -eq "$HOME\Downloads"
            }

            Should -Invoke Initialize-NatNetwork -ModuleName 'AllToolsUtilities' -Times 0
        }

        It "Should use user-specified values" {
            Install-ContainerTools `
                -ContainerDVersion '7.8.9' `
                -BuildKitVersion '4.5.6' `
                -NerdCTLVersion '3.2.1' `
                -InstallPath 'TestDrive:\Install Directory' `
                -DownloadPath 'TestDrive:\Download Directory' `
                -Force -Confirm:$false


            Should -Invoke Install-Containerd -ModuleName 'AllToolsUtilities' -Times 1 -Exactly -Scope It `
                -ParameterFilter {
                $Version -eq '7.8.9' -and
                $InstallPath -eq "TestDrive:\Install Directory\Containerd" -and
                $DownloadPath -eq "TestDrive:\Download Directory" -and
                $Setup -eq $false
            }

            Should -Invoke Install-Buildkit -ModuleName 'AllToolsUtilities' -Times 1 -Exactly -Scope It `
                -ParameterFilter {
                $Version -eq '4.5.6' -and
                $InstallPath -eq "TestDrive:\Install Directory\BuildKit" -and
                $DownloadPath -eq "TestDrive:\Download Directory" -and
                $Setup -eq $false
            }

            Should -Invoke Install-Nerdctl -ModuleName 'AllToolsUtilities' -Times 1 -Exactly -Scope It `
                -ParameterFilter {
                $Version -eq '3.2.1' -and
                $InstallPath -eq "TestDrive:\Install Directory\nerdctl" -and
                $DownloadPath -eq "TestDrive:\Download Directory"
            }

            Should -Invoke Initialize-NatNetwork -ModuleName 'AllToolsUtilities' -Times 0
        }

        It "Should continue installation of other tools on failure" {
            Mock Install-Containerd -ModuleName 'AllToolsUtilities' -MockWith { Throw 'Error message' }

            Install-ContainerTools -Force -Confirm:$false

            $Error[0].Exception.Message | Should -Be 'Containerd Installation failed. Error message'

            foreach ($tool in @('buildkit', 'nerdctl')) {
                Should -Invoke "Install-$tool" -ModuleName 'AllToolsUtilities' -Times 1 -Exactly -Scope It
            }
        }

        It "Should register services and initialize NAT network when argument '-RegisterServices' is passed" {
            Install-ContainerTools `
                -InstallPath 'TestDrive:\Install Directory' `
                -Force -Confirm:$false `
                -RegisterServices

            Should -Invoke Install-Containerd -ModuleName 'AllToolsUtilities' -Scope It -ParameterFilter { $Setup -eq $true }
            Should -Invoke Install-Buildkit -ModuleName 'AllToolsUtilities' -Scope It -ParameterFilter { $Setup -eq $true }
            Should -Invoke Initialize-NatNetwork -ModuleName 'AllToolsUtilities' -Times 1
        }

        It "Should not throw an error if initializing NAT network fails" {
            Mock Initialize-NatNetwork -ModuleName 'AllToolsUtilities' -MockWith { throw 'Error message' }

            { Install-ContainerTools -InstallPath 'TestDrive:\Install Directory' -Force -Confirm:$false -RegisterServices } | Should -Not -Throw
            $Error[0].Exception.Message | Should -Be 'Failed to initialize NAT network. Error message'
        }
    }
}