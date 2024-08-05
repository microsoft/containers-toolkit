###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


Describe "ContainerNetworkTools.psm1" {
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'Containers-Toolkit'

        Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\ContainerNetworkTools.psm1" -Force
        Import-Module -Name "$RootPath\Tests\TestData\MockClasses.psm1" -Force
    }

    AfterEach {
        $ENV:PESTER = $false
    }

    AfterAll {
        Get-ChildItem -Path 'TestDrive:\' | Remove-Item -Recurse -Force

        Remove-Module -Name "CommonToolUtilities" -Force -ErrorAction Ignore
        Remove-Module -Name "ContainerNetworkTools" -Force -ErrorAction Ignore
        Remove-Module -Name "MockClasses" -Force -ErrorAction Ignore
    }

    Context "Install-WinCNIPlugin" -Tag "Install-WinCNIPlugin" {
        BeforeAll {
            Mock Get-WinCNILatestVersion { return '1.0.0' } -ModuleName 'ContainerNetworkTools'
            Mock Uninstall-WinCNIPlugin -ModuleName "ContainerNetworkTools"
            Mock New-Item -ModuleName 'ContainerNetworkTools'
            Mock Get-InstallationFile -ModuleName 'ContainerNetworkTools'
            Mock Expand-Archive -ModuleName 'ContainerNetworkTools'
            Mock Remove-Item -ModuleName 'ContainerNetworkTools'
            Mock Test-EmptyDirectory  -ModuleName 'ContainerNetworkTools' -MockWith { return $true }
            Mock Install-ContainerToolConsent -ModuleName 'ContainerNetworkTools' -MockWith { return $true }
            Mock Install-WinCNIPlugin -ModuleName 'ContainerNetworkTools'

            $Script:WinCNIRepo = 'https://github.com/microsoft/windows-container-networking/releases/download'
        }

        It 'Should not process on implicit request for validation (WhatIfPreference)' {
            {
                $WhatIfPreference = $true
                Install-WinCNIPlugin
            }
            Should -Invoke -CommandName Install-WinCNIPlugin -ModuleName 'ContainerNetworkTools' -Exactly -Times 0 -Scope It
        }

        It 'Should not process on explicit request for validation (-WhatIf)' {
            { Install-WinCNIPlugin -WhatIf }
            Should -Invoke -CommandName Install-WinCNIPlugin -ModuleName 'ContainerNetworkTools' -Exactly -Times 0 -Scope It
        }

        It "Should use defaults" {
            Install-WinCNIPlugin -Force -Confirm:$false

            Should -Invoke Uninstall-WinCNIPlugin -ModuleName 'ContainerNetworkTools' -Times 0 -Exactly -Scope It

            $MockZipFileName = 'windows-container-networking-cni-amd64-v1.0.0.zip'
            Should -Invoke Get-InstallationFile -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "WinCNIPlugin"
                        Uri          = "$Script:WinCNIRepo/v1.0.0/$MockZipFileName"
                        Version      = '1.0.0'
                        DownloadPath = "$HOME\Downloads"
                    }
                )
            }
            Should -Invoke Expand-Archive -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Path -eq "$HOME\Downloads\$MockZipFileName"
                $DestinationPath -eq "$Env:ProgramFiles\Containerd\cni"
            }
            Should -Invoke Remove-Item -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Path -eq "$HOME\Downloads\$MockZipFileName"
            }
        }

        It "Should call function with user-specified values" {
            Install-WinCNIPlugin -WinCNIVersion '1.2.3' -WinCNIPath 'TestDrive:\WinCNI\bin' -Force -Confirm:$false

            Should -Invoke Uninstall-WinCNIPlugin -ModuleName 'ContainerNetworkTools' -Times 0 -Exactly -Scope It

            $MockZipFileName = 'windows-container-networking-cni-amd64-v1.2.3.zip'
            Should -Invoke Get-InstallationFile -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "WinCNIPlugin"
                        Uri          = "$Script:WinCNIRepo/v1.2.3/$MockZipFileName"
                        Version      = '1.2.3'
                        DownloadPath = "$HOME\Downloads"
                    }
                )
            }
            Should -Invoke Expand-Archive -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Path -eq "$HOME\Downloads\$MockZipFileName"
                $DestinationPath -eq "TestDrive:\WinCNI\bin"
            }
            Should -Invoke Remove-Item -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Path -eq "$HOME\Downloads\$MockZipFileName"
            }
        }

        It "Should uninstall tool if it is already installed" {
            Mock Test-EmptyDirectory -ModuleName 'ContainerNetworkTools' -MockWith { return $false }

            Install-WinCNIPlugin -Force -Confirm:$false

            Should -Invoke Uninstall-WinCNIPlugin -ModuleName 'ContainerNetworkTools' -Times 1 -Exactly -Scope It `
                -ParameterFilter { $Path -eq "$Env:ProgramFiles\Containerd\cni" }
        }

        It "Should throw an error if uninstallation fails" {
            Mock Test-EmptyDirectory -ModuleName 'ContainerNetworkTools' -MockWith { return $false }
            Mock Uninstall-WinCNIPlugin -ModuleName 'ContainerNetworkTools' -MockWith { throw 'Error' }

            { Install-WinCNIPlugin -Confirm:$false } | Should -Throw "Windows CNI plugin installation failed. Error"
        }
    }

    Context "Initialize-NatNetwork" -Tag "Initialize-NatNetwork" {
        BeforeAll {
            Mock Get-DefaultInstallPath -ModuleName 'ContainerNetworkTools' -MockWith { return 'TestDrive:\Program Files\Containerd' }
            Mock Get-NetRoute -ModuleName 'ContainerNetworkTools' -MockWith { @{NextHop = "99.2.0.8" } }
            Mock Test-EmptyDirectory -ModuleName 'ContainerNetworkTools' -MockWith { return $false }
            Mock Get-WinCNILatestVersion { return '1.0.0' } -ModuleName 'ContainerNetworkTools'
            Mock Get-Module -ModuleName 'ContainerNetworkTools' -MockWith { return @{} }
            Mock Import-Module -ModuleName 'ContainerNetworkTools'
            Mock Get-HnsNetwork -ModuleName 'ContainerNetworkTools'
            Mock New-HNSNetwork -ModuleName 'ContainerNetworkTools'
            Mock Restart-Service -ModuleName 'ContainerNetworkTools'
        }

        It "Should use defaults" {
            Initialize-NatNetwork -Force

            Should -Invoke Get-NetRoute -ModuleName 'ContainerNetworkTools'
            Should -Invoke New-HNSNetwork -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Name -eq 'NAT'
                $Type -eq 'NAT'
                $Gateway -eq '99.2.0.8'
                $AddressPrefix -eq '99.2.0.0/16'
            }
            $MockConfFilePath = "TestDrive:\Program Files\Containerd\cni\conf\0-containerd-nat.conf"
            $MockConfFilePath | Should -Exist
            $MockConfFilePath | Should -FileContentMatch "`"cniVersion`": `"1.0.0`""
        }

        It "Should use user-specified values" {
            Initialize-NatNetwork -NetworkName 'TestN/W' -Gateway '80.7.9.5' -CIDR 32 -WinCNIVersion '2.5.7' -WinCNIPath 'TestDrive:\Test Dir\cni' -Force

            Should -Invoke Get-DefaultInstallPath -ModuleName 'ContainerNetworkTools' -Times 0 -Scope It
            Should -Invoke Get-NetRoute -ModuleName 'ContainerNetworkTools' -Times 0 -Scope It
            Should -Invoke Get-WinCNILatestVersion -ModuleName 'ContainerNetworkTools' -Times 0 -Scope It
            Should -Invoke New-HNSNetwork -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Name -eq 'TestN/W'
                $Type -eq 'NAT'
                $Gateway -eq '80.7.9.5'
                $AddressPrefix -eq '80.7.9.5/32'
            }

            $MockConfFilePath = "TestDrive:\Test Dir\cni\conf\0-containerd-nat.conf"
            $MockConfFilePath | Should -Exist
            $MockConfFilePath | Should -FileContentMatch "`"cniVersion`": `"2.5.7`""
        }

        It "Should install missing WinCNI plugins if user consents" {
            Mock Test-EmptyDirectory -ModuleName 'ContainerNetworkTools' -MockWith { return $true }
            Mock New-Item -ModuleName 'ContainerNetworkTools'
            Mock Install-WinCNIPlugin -ModuleName 'ContainerNetworkTools'

            $mockedConsent = [ActionConsent]::Yes.value__
            Mock Get-Host -ModuleName "ContainerNetworkTools" -MockWith { return [UITest]::new($mockedConsent) }

            Initialize-NatNetwork
            Should -Invoke Install-WinCNIPlugin -ModuleName 'ContainerNetworkTools'
        }

        It "Should throw an error if WinCNI plugins do not exist and user does not consent to install them" {
            Mock Test-EmptyDirectory -ModuleName 'ContainerNetworkTools' -MockWith { return $true }

            $mockedConsent = [ActionConsent]::No.value__
            Mock Get-Host -ModuleName "ContainerNetworkTools" -MockWith { return [UITest]::new($mockedConsent) }

            $ENV:PESTER = $true
            { Initialize-NatNetwork } | Should -Throw "Windows CNI plugins have not been installed*"
        }

        It "Should throw error if HostNetworkingService and HNS module are not installed" {
            Mock Get-Module -ModuleName 'ContainerNetworkTools'

            { Initialize-NatNetwork -Force } | Should -Throw "Could not import HNS module.*"
            Should -Invoke Get-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HostNetworkingService' -or $Name -eq 'HNS' }
        }

        It "Should first check HostNetworkingService module by default" {
            Mock Get-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HostNetworkingService' } -MockWith { return @{} }
            Mock Get-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HNS' }

            Initialize-NatNetwork -Force

            Should -Invoke Import-Module -Times 0 -Scope It -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HNS' }
            Should -Invoke Get-Module -Times 0 -Scope It -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HNS' }
        }

        It "Should use HNS module if HostNetworkingService is not installed" {
            Mock Get-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HostNetworkingService' }
            Mock Get-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HNS' } -MockWith { return @{} }

            Initialize-NatNetwork -Force

            Should -Invoke Import-Module -Times 0 -Scope It -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HostNetworkingService' }
            Should -Invoke Import-Module -Times 1 -Scope It -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HNS' }
        }

        It "Should throw an error when importing HNS module fails" {
            Mock Get-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HostNetworkingService' }
            Mock Get-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HNS' } -MockWith { return @{} }
            Mock Import-Module -ModuleName 'ContainerNetworkTools' -MockWith { Throw 'Error message.' }

            { Initialize-NatNetwork -Force } | Should -Throw "Could not import HNS module. Error message."
        }

        It "Should throw an error if network exists" {
            Mock Get-HnsNetwork -ModuleName 'ContainerNetworkTools' -MockWith { return @{ Name = 'TestN/W' } }
            { Initialize-NatNetwork -NetworkName 'TestN/W' -Force } | Should -Not -Throw
            Should -Invoke New-HNSNetwork -Times 0 -Scope It -ModuleName 'ContainerNetworkTools'
        }

        It "Should throw an error if creating a new network fails" {
            Mock New-HNSNetwork -ModuleName 'ContainerNetworkTools' -MockWith { Throw 'Error message' }
            { Initialize-NatNetwork -NetworkName 'TestN/W' -Force } | Should -Throw "Could not create a new NAT network TestN/W with Gateway 99.2.0.8 and Subnet mask 99.2.0.0/16.*"
        }
    }

    Context "Uninstall-WinCNIPlugin" -Tag "Uninstall-WinCNIPlugin" {
        BeforeAll {
            Mock Get-DefaultInstallPath -ModuleName 'ContainerNetworkTools' -MockWith { return 'TestDrive:\Program Files\Containerd' }
            Mock Test-EmptyDirectory -ModuleName 'ContainerNetworkTools' -MockWith { return  $false }
            Mock Uninstall-ContainerToolConsent -ModuleName 'ContainerNetworkTools' -MockWith { return $true }
            Mock Remove-Item -ModuleName 'ContainerNetworkTools'
        }

        It "Should successfully uninstall WinCNI plugins" {
            Mock Uninstall-WinCNIPluginHelper -ModuleName 'ContainerNetworkTools'

            Uninstall-WinCNIPlugin -Confirm:$false -Path 'TestDrive:\Program Files\cni' -Force

            Should -Invoke Uninstall-WinCNIPluginHelper -Times 1 -Scope It -ModuleName "ContainerNetworkTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\cni' }
        }

        It "Should successfully uninstall WinCNI plugins from default path" {
            Mock Uninstall-WinCNIPluginHelper -ModuleName 'ContainerNetworkTools'

            Uninstall-WinCNIPlugin -Confirm:$false -Force

            Should -Invoke Uninstall-WinCNIPluginHelper -Times 1 -Scope It -ModuleName "ContainerNetworkTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Containerd\cni' }
        }

        It "Should throw an error if user does not consent to uninstalling WinCNIPlugin" {
            Mock Uninstall-ContainerToolConsent -ModuleName 'ContainerNetworkTools' -MockWith { return $false }

            $ENV:PESTER = $true
            { Uninstall-WinCNIPlugin -Confirm:$false -Path 'TestDrive:\Program Files\cni' -Force:$false } | Should -Throw "Windows CNI plugins uninstallation cancelled."
        }

        It "Should successfully call uninstall WinCNIPlugin helper function" {
            Uninstall-WinCNIPluginHelper -Path 'TestDrive:\TestDir\cni'

            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "ContainerNetworkTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\TestDir\cni' }
        }

        It "Should do nothing if WinCNI plugins is not installed at specified path" {
            Mock Test-EmptyDirectory -ModuleName 'ContainerNetworkTools' -MockWith { return $true }

            Uninstall-WinCNIPluginHelper -Path 'TestDrive:\TestDir\cni'
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "ContainerNetworkTools"

            $Error[0].Exception.Message | Should -Be 'Windows CNI plugin does not exist at TestDrive:\TestDir\cni or the directory is empty.'
        }
    }
}