###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


Describe "NerdctlTools.psm1" {
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'Containers-Toolkit'
        Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\NerdctlTools.psm1"
        Import-Module -Name "$ModuleParentPath\Public\ContainerdTools.psm1"
        Import-Module -Name "$ModuleParentPath\Public\ContainerNetworkTools.psm1"
        Import-Module -Name "$ModuleParentPath\Public\NerdctlTools.psm1" -Force
    }

    AfterEach {
        $ENV:PESTER = $false
    }

    AfterAll {
        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\BuildkitTools.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\ContainerdTools.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\ContainerNetworkTools.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\NerdctlTools.psm1" -Force -ErrorAction Ignore
    }

    Context "Install-Nerdctl" -Tag "Install-Nerdctl" {
        BeforeAll {
            Mock Get-NerdctlLatestVersion { return '7.9.8' } -ModuleName 'NerdctlTools'
            Mock Uninstall-Nerdctl -ModuleName "NerdctlTools"
            Mock Get-InstallationFile -ModuleName 'NerdctlTools'
            Mock Install-RequiredFeature -ModuleName 'NerdctlTools'
            Mock Get-Command -ModuleName 'NerdctlTools'
            Mock Get-ChildItem -ModuleName 'NerdctlTools'
            Mock Test-EmptyDirectory  -ModuleName 'NerdctlTools' -MockWith { return $true }
            Mock Install-Containerd -ModuleName 'NerdctlTools'
            Mock Install-Buildkit -ModuleName 'NerdctlTools'
            Mock Install-WinCNIPlugin -ModuleName 'NerdctlTools'
            Mock Install-Nerdctl -ModuleName 'NerdctlTools'
            Mock Test-CheckSum -ModuleName 'NerdctlTools' -MockWith { return $true }
            Mock Remove-Item -ModuleName 'NerdctlTools'

            $Script:nerdctlRepo = 'https://github.com/containerd/nerdctl/releases/download'
            $Script:TestDownloadPath = "$HOME\Downloads\nerdctl-7.9.8-windows-amd64.tar.gz"
        }

        It 'Should not process on implicit request for validation (WhatIfPreference)' {
            {
                $WhatIfPreference = $true
                Install-Nerdctl
            }
            Should -Invoke -CommandName Install-Nerdctl -ModuleName 'NerdctlTools' -Exactly -Times 0 -Scope It
        }

        It 'Should not process on explicit request for validation (-WhatIf)' {
            { Install-Nerdctl -WhatIf }
            Should -Invoke -CommandName Install-Nerdctl -ModuleName 'NerdctlTools' -Exactly -Times 0 -Scope It
        }

        It "Should use defaults" {
            Install-Nerdctl -Force -Confirm:$false

            Should -Invoke Uninstall-Nerdctl -ModuleName 'NerdctlTools' -Times 0 -Exactly -Scope It
            Should -Invoke Get-InstallationFile -ModuleName 'NerdctlTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "nerdctl"
                        Uri          = "$Script:nerdctlRepo/v7.9.8/nerdctl-7.9.8-windows-amd64.tar.gz"
                        Version      = '7.9.8'
                        DownloadPath = "$Script:TestDownloadPath"
                    }
                )
            }

            Should -Invoke Test-CheckSum -ModuleName 'NerdctlTools' -Times 1 -ParameterFilter {
                $DownloadedFile -eq "$Script:TestDownloadPath" -and
                $ChecksumUri -eq "$Script:nerdctlRepo/v7.9.8/SHA256SUMS"
            }

            Should -Invoke Install-RequiredFeature -ModuleName 'NerdctlTools' -ParameterFilter {
                $Feature -eq "nerdctl" -and
                $InstallPath -eq "$Env:ProgramFiles\nerdctl" -and
                $DownloadPath -eq "$HOME\Downloads\nerdctl-7.9.8-windows-amd64.tar.gz" -and
                $EnvPath -eq "$Env:ProgramFiles\nerdctl" -and
                $cleanup -eq $true
            }

            Should -Invoke Install-Containerd -ModuleName 'NerdctlTools' -Times 0 -Exactly -Scope It
            Should -Invoke Install-Buildkit -ModuleName 'NerdctlTools' -Times 0 -Exactly -Scope It
            Should -Invoke Install-WinCNIPlugin -ModuleName 'NerdctlTools' -Times 0 -Exactly -Scope It
        }

        It "Should call function with user-specified values" {
            Install-Nerdctl -Version '1.2.3' -InstallPath 'TestDrive:\nerdctl' -DownloadPath 'TestDrive:\Downloads' -Dependencies 'containerd' -Force -Confirm:$false

            Should -Invoke Uninstall-Nerdctl -ModuleName 'NerdctlTools' -Times 0 -Exactly -Scope It
            Should -Invoke Get-InstallationFile -ModuleName 'NerdctlTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "nerdctl"
                        Uri          = "$Script:nerdctlRepo/v1.2.3/nerdctl-1.2.3-windows-amd64.tar.gz"
                        Version      = '1.2.3'
                        DownloadPath = "$HOME\Downloads"
                    }
                )
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'NerdctlTools' -ParameterFilter {
                $Feature -eq "nerdctl"
                $InstallPath -eq 'TestDrive:\nerdctl'
                $DownloadPath -eq 'TestDrive:\Downloads\nerdctl-1.2.3-windows-amd64.tar.gz'
                $EnvPath -eq 'TestDrive:\nerdctl\bin'
                $cleanup -eq $true
            }

            Should -Invoke Install-Containerd -ModuleName 'NerdctlTools' -Times 1 -Exactly -Scope It
            Should -Invoke Install-Buildkit -ModuleName 'NerdctlTools' -Times 0 -Exactly -Scope It
            Should -Invoke Install-WinCNIPlugin -ModuleName 'NerdctlTools' -Times 0 -Exactly -Scope It
        }

        It "should throw an error when checksum verification fails" {
            Mock Test-CheckSum -ModuleName 'NerdctlTools' -MockWith { return $false }

            { Install-Nerdctl -Force -Confirm:$false } | Should -Throw "Checksum verification failed for $Script:TestDownloadPath"
            Should -Invoke Remove-Item -ModuleName 'NerdctlTools' -ParameterFilter {
                $Path -eq "$Script:TestDownloadPath"
            }
        }

        It "Should uninstall tool if it is already installed" {
            Mock Test-EmptyDirectory -ModuleName 'NerdctlTools' -MockWith { return $false }

            Install-Nerdctl -Force -Confirm:$false

            Should -Invoke Uninstall-Nerdctl -ModuleName 'NerdctlTools' -Times 1 -Exactly -Scope It `
                -ParameterFilter { $Path -eq "$Env:ProgramFiles\nerdctl" }
        }

        It "Should throw an error if uninstallation fails" {
            Mock Test-EmptyDirectory -ModuleName 'NerdctlTools' -MockWith { return $false }
            Mock Uninstall-Nerdctl -ModuleName 'NerdctlTools' -MockWith { throw 'Error' }

            { Install-Nerdctl -Confirm:$false } | Should -Throw "nerdctl installation failed. Error"
        }

        It "Should install all dependencies if 'All' is specified" {
            Install-Nerdctl -Dependencies 'All' -Confirm:$false

            Should -Invoke Install-Containerd -ModuleName 'NerdctlTools' -Times 1 -Exactly -Scope It
            Should -Invoke Install-Buildkit -ModuleName 'NerdctlTools' -Times 1 -Exactly -Scope It
            Should -Invoke Install-WinCNIPlugin -ModuleName 'NerdctlTools' -Times 1 -Exactly -Scope It
        }

        It "Should install specified dependencies" {
            Install-Nerdctl -Dependencies 'containerd' -Confirm:$false

            Should -Invoke Install-Containerd -ModuleName 'NerdctlTools' -Times 1 -Exactly -Scope It
            Should -Invoke Install-Buildkit -ModuleName 'NerdctlTools' -Times 0 -Exactly -Scope It
            Should -Invoke Install-WinCNIPlugin -ModuleName 'NerdctlTools' -Times 0 -Exactly -Scope It
        }
    }

    Context "Uninstall-Nerdctl" -Tag "Uninstall-Nerdctl" {
        BeforeAll {
            Mock Get-DefaultInstallPath -ModuleName 'NerdctlTools' -MockWith { return 'TestDrive:\Program Files\nerdctl' }
            Mock Test-EmptyDirectory -ModuleName 'NerdctlTools' -MockWith { return  $false }
            Mock Remove-Item -ModuleName 'NerdctlTools'
            Mock Remove-FeatureFromPath -ModuleName 'NerdctlTools'
            Mock Uninstall-ProgramFiles -ModuleName 'NerdctlTools'
        }

        It "Should successfully uninstall nerdctl" {
            Mock Uninstall-NerdctlHelper -ModuleName 'NerdctlTools'

            Uninstall-Nerdctl -Path 'TestDrive:\Program Files\nerdctl' -Confirm:$false -Force

            Should -Invoke Uninstall-NerdctlHelper -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\nerdctl' }
        }

        It "Should successfully uninstall nerdctl from default path" {
            Mock Uninstall-NerdctlHelper -ModuleName 'NerdctlTools'

            Uninstall-Nerdctl -Confirm:$false -Force

            Should -Invoke Uninstall-NerdctlHelper -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\nerdctl' }
        }

        It "Should throw an error if user does not consent to uninstalling nerdctl" {
            $ENV:PESTER = $true
            { Uninstall-Nerdctl -Confirm:$false -Path 'TestDrive:\Program Files\nerdctl'-Force:$false } | Should -Throw 'nerdctl uninstallation cancelled.'
        }

        It "Should do nothing if nerdctl is not installed at specified path" {
            Mock Test-EmptyDirectory -ModuleName 'NerdctlTools' -MockWith { return $true }

            Uninstall-Nerdctl -Confirm:$false -Force
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "NerdctlTools"
            Should -Invoke Remove-FeatureFromPath -Times 0 -Scope It -ModuleName "NerdctlTools"
        }

        It "Should successfully call uninstall nerdctl helper function" {
            Uninstall-NerdctlHelper -Path 'TestDrive:\Program Files\nerdctl'

            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\nerdctl' }
            Should -Invoke Uninstall-ProgramFiles -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Path -eq "$ENV:ProgramData\nerdctl" }
            Should -Invoke Remove-FeatureFromPath -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Feature -eq "nerdctl" }
        }

        It "Should write an error if nerdctl is not installed at specified path" {
            Mock Test-EmptyDirectory -ModuleName 'NerdctlTools' -MockWith { return $true }

            Uninstall-NerdctlHelper -Path 'TestDrive:\Program Files\nerdctl'

            $Error[0].Exception.Message | Should -BeExactly 'nerdctl does not exist at TestDrive:\Program Files\nerdctl or the directory is empty.'
        }
    }
}
