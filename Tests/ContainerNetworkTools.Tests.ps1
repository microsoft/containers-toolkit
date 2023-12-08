Describe "ContainerNetworkTools.psm1" {
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'ContainerToolsForWindows'
        Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\ContainerNetworkTools.psm1" -Force
    }

    AfterAll {
        Get-ChildItem -Path 'TestDrive:\' | Remove-Item -Recurse -Force

        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\ContainerNetworkTools.psm1" -Force -ErrorAction Ignore
    }

    Context "Install-WinCNIPlugin" -Tag "Install-WinCNIPlugin" {
        BeforeAll {
            Mock Get-WinCNILatestVersion { return '1.0.0' } -ModuleName 'ContainerNetworkTools'
            Mock Uninstall-WinCNIPlugin -ModuleName "ContainerNetworkTools"
            Mock New-Item -ModuleName 'ContainerNetworkTools'
            Mock Get-InstallationFiles -ModuleName 'ContainerNetworkTools'
            Mock Expand-Archive -ModuleName 'ContainerNetworkTools'
            Mock Remove-Item -ModuleName 'ContainerNetworkTools'

            $WinCNIRepo = 'https://github.com/microsoft/windows-container-networking/releases/download'
        }
        
        It "Should use defaults" {
            Install-WinCNIPlugin
            
            Should -Invoke Uninstall-WinCNIPlugin -ModuleName 'ContainerNetworkTools' -Times 1 -Exactly -Scope It `
                -ParameterFilter { $Path -eq "$Env:ProgramFiles\Containerd\cni" }

            $MockZipFileName = 'windows-container-networking-cni-amd64-v1.0.0.zip'
            Should -Invoke Get-InstallationFiles -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "WinCNIPlugin"
                        Uri          = "$WinCNIRepo/v1.0.0/$MockZipFileName"
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
            Install-WinCNIPlugin -WinCNIVersion '1.2.3' -WinCNIPath 'TestDrive:\WinCNI\bin'

            Should -Invoke Uninstall-WinCNIPlugin -ModuleName 'ContainerNetworkTools' `
                -ParameterFilter { $Path -eq 'TestDrive:\WinCNI' }

            $MockZipFileName = 'windows-container-networking-cni-amd64-v1.2.3.zip'
            Should -Invoke Get-InstallationFiles -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "WinCNIPlugin"
                        Uri          = "$WinCNIRepo/v1.2.3/$MockZipFileName"
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
    }
    
    Context "Initialize-NatNetwork" -Tag "Initialize-NatNetwork" {
        BeforeAll {
            Mock Get-DefaultInstallPath -ModuleName 'ContainerNetworkTools' -MockWith { return 'TestDrive:\Program Files\Containerd' }
            Mock Test-EmptyDirectory -ModuleName 'ContainerNetworkTools' -MockWith { return $false }
            Mock Get-WinCNILatestVersion { return '1.0.0' } -ModuleName 'ContainerNetworkTools'
            Mock Get-Module -ModuleName 'ContainerNetworkTools' -MockWith { return @{} }
            Mock Import-Module -ModuleName 'ContainerNetworkTools'
            Mock Get-HnsNetwork -ModuleName 'ContainerNetworkTools'
            Mock New-HNSNetwork -ModuleName 'ContainerNetworkTools'
            Mock Get-NetRoute -ModuleName 'ContainerNetworkTools' -MockWith { @{NextHop = "99.2.0.8" } }
        }

        It "Should use defaults" {
            Initialize-NatNetwork

            Should -Invoke Import-Module -ModuleName 'ContainerNetworkTools' 
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
            Initialize-NatNetwork -NetworkName 'TestN/W' -Gateway '80.7.9.5' -CIDR 32 -WinCNIVersion '2.5.7' -WinCNIPath 'TestDrive:\Test Dir\cni'

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

            { Initialize-NatNetwork } | Should -Throw "Windows CNI plugins have not been installed*"
        }

        It "Should install HNS module if it does not exist" {
            Mock Get-Module -ModuleName 'ContainerNetworkTools'
            Mock Install-Module -ModuleName 'ContainerNetworkTools'

            Initialize-NatNetwork
            Should -Invoke Install-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HNS' }
            Should -Invoke Import-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HNS' }
        }

        It "Should download HNS module file if it does not exist and failed to install module" {
            Mock Get-Module -ModuleName 'ContainerNetworkTools'
            Mock Install-Module -ModuleName 'ContainerNetworkTools' -MockWith { Throw 'Could not download HNS module' }
            Mock Test-Path -ModuleName 'ContainerNetworkTools' -MockWith { $false } `
                -ParameterFilter { $path -eq "$Env:ProgramFiles\containerd\cni\hns.psm1" } 
            Mock Get-InstallationFiles -ModuleName 'ContainerNetworkTools'

            Initialize-NatNetwork
            Should -Invoke Install-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq 'HNS' }
            Should -Invoke Get-InstallationFiles -ModuleName 'ContainerNetworkTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "HNS.psm1"
                        Uri          = 'https://raw.githubusercontent.com/microsoft/SDN/master/Kubernetes/windows/hns.psm1'
                        DownloadPath = "$Env:ProgramFiles\containerd\cni"
                    }
                )
            }
            Should -Invoke Import-Module -ModuleName 'ContainerNetworkTools' -ParameterFilter { $Name -eq "$Env:ProgramFiles\containerd\cni\hns.psm1" }
        }

        It "Should throw an error when importing HNS module fails" {
            Mock Test-Path -ModuleName 'ContainerNetworkTools' -MockWith { $true } `
                -ParameterFilter { $path -eq "$Env:ProgramFiles\containerd\cni\hns.psm1" } 
            Mock Import-Module -ModuleName 'ContainerNetworkTools' -MockWith { Throw 'Error message.' }

            { Initialize-NatNetwork } | Should -Throw "Could not import HNS module. Error message."
        }
        
        It "Should throw an error if network exists" {
            Mock Get-HnsNetwork -ModuleName 'ContainerNetworkTools' -MockWith { return @{Name = 'TestN/W' } }
            { Initialize-NatNetwork -NetworkName 'TestN/W' } | Should -Throw "TestN/W already exists.*"
        }
        
        It "Should throw an error if creating a new network fails" {
            Mock New-HNSNetwork -ModuleName 'ContainerNetworkTools' -MockWith { Throw 'Error message' }
            { Initialize-NatNetwork -NetworkName 'TestN/W' } | Should -Throw "Could not create a new NAT network TestN/W with Gateway 99.2.0.8 and Subnet mask 99.2.0.0/16.*"
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

            Uninstall-WinCNIPlugin -Path 'TestDrive:\Program Files\cni'

            Should -Invoke Uninstall-WinCNIPluginHelper -Times 1 -Scope It -ModuleName "ContainerNetworkTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\cni' }
        }

        It "Should successfully uninstall WinCNI plugins from default path" {
            Mock Uninstall-WinCNIPluginHelper -ModuleName 'ContainerNetworkTools'

            Uninstall-WinCNIPlugin

            Should -Invoke Uninstall-WinCNIPluginHelper -Times 1 -Scope It -ModuleName "ContainerNetworkTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Containerd\cni' }
        }

        It "Should throw an error if user does not consent to uninstalling WinCNIPlugin" {
            Mock Uninstall-ContainerToolConsent -ModuleName 'ContainerNetworkTools' -MockWith { return $false }

            { Uninstall-WinCNIPlugin -Path 'TestDrive:\Program Files\cni' } | Should -Throw "Windows CNI plugin uninstallation cancelled."
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