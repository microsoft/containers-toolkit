###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


using module "..\containers-toolkit\Private\CommonToolUtilities.psm1"

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

        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\ContainerNetworkTools.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$RootPath\Tests\TestData\MockClasses.psm1" -Force -ErrorAction Ignore
    }

    Context "Install-WinCNIPlugin" -Tag "Install-WinCNIPlugin" {
        BeforeAll {
            $Script:ToolName = 'WinCNIPlugin'
            $Script:WinCNIRepo = 'https://github.com/microsoft/windows-container-networking/releases/download'
            $Script:MockZipFileName = "windows-container-networking-cni-amd64-v1.0.0.zip"
            $Script:TestDownloadPath = "$HOME\Downloads\$Script:MockZipFileName"

            Mock Get-WinCNILatestVersion { return '1.0.0' } -ModuleName 'ContainerNetworkTools'
            Mock Uninstall-WinCNIPlugin -ModuleName "ContainerNetworkTools"
            Mock New-Item -ModuleName 'ContainerNetworkTools'
            Mock Get-Item -ModuleName 'ContainerNetworkTools' -MockWith { @{ Path = $Script:TestDownloadPath } } -ParameterFilter { $Path -eq $Script:TestDownloadPath }
            Mock Get-InstallationFile -ModuleName 'ContainerNetworkTools' -MockWith { $Script:TestDownloadPath }
            Mock Expand-Archive -ModuleName 'ContainerNetworkTools'
            Mock Remove-Item -ModuleName 'ContainerNetworkTools'
            Mock Test-EmptyDirectory  -ModuleName 'ContainerNetworkTools' -MockWith { return $true }
            Mock Install-WinCNIPlugin -ModuleName 'ContainerNetworkTools'
            Mock Test-Path -ModuleName 'ContainerNetworkTools' -MockWith { return $true }
            Mock Install-RequiredFeature -ModuleName 'ContainerNetworkTools'
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
            Should -Invoke Get-InstallationFile -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $fileParameters[0].Feature -eq "$Script:ToolName" -and
                $fileParameters[0].Repo -eq "microsoft/windows-container-networking" -and
                $fileParameters[0].Version -eq 'latest' -and
                $fileParameters[0].DownloadPath -eq "$HOME\Downloads"
                [string]::IsNullOrWhiteSpace($fileParameters.ChecksumSchemaFile) -and
                $fileParameters[0].FileFilterRegEx -eq $null
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Feature -eq "$Script:ToolName" -and
                $InstallPath -eq "$Env:ProgramFiles\Containerd\cni\bin" -and
                $SourceFile -eq "$Script:TestDownloadPath" -and
                $EnvPath -eq $null -and
                $cleanup -eq $true -and
                $UpdateEnvPath -eq $false
            }
        }

        It "Should call function with user-specified values" {
            # Mocks
            $MockZipFileName = 'windows-container-networking-cni-386-v1.2.3.zip'
            $MockDownloadFilePath = "$HOME\Downloads\$MockZipFileName"
            Mock Get-InstallationFile -ModuleName 'ContainerNetworkTools' -MockWith { $MockDownloadFilePath }

            # Test
            Install-WinCNIPlugin -WinCNIVersion '1.2.3' -WinCNIPath 'TestDrive:\WinCNI\bin' -SourceRepo "containernetworking/plugins" -OSArchitecture '386' -Force -Confirm:$false

            # Assertions
            Should -Invoke Uninstall-WinCNIPlugin -ModuleName 'ContainerNetworkTools' -Times 0 -Exactly -Scope It
            Should -Invoke Get-InstallationFile -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $fileParameters[0].Version -eq '1.2.3' -and
                $fileParameters[0].Repo -eq 'containernetworking/plugins' -and
                $fileParameters[0].OSArchitecture -eq '386' -and
                $fileParameters[0].FileFilterRegEx -eq ".*tgz(.SHA512)?$"
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Feature -eq "$Script:ToolName" -and
                $InstallPath -eq 'TestDrive:\WinCNI\bin' -and
                $SourceFile -eq $MockDownloadFilePath -and
                $cleanup -eq $true -and
                $UpdateEnvPath -eq $false
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