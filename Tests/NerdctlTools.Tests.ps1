Describe "NerdctlTools.psm1" {
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'ContainerToolsForWindows'
        Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\NerdctlTools.psm1" -Force
    }

    AfterAll {
        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\NerdctlTools.psm1" -Force -ErrorAction Ignore
    }

    Context "Install-Nerdctl" -Tag "Install-Nerdctl" {
        BeforeAll {
            Mock Get-NerdctlLatestVersion { return '7.9.8' } -ModuleName 'NerdctlTools'
            Mock Uninstall-Nerdctl -ModuleName "NerdctlTools"
            Mock Get-InstallationFiles -ModuleName 'NerdctlTools'
            Mock Install-RequiredFeature -ModuleName 'NerdctlTools'
            Mock Get-Command -ModuleName 'NerdctlTools'
            Mock Get-ChildItem -ModuleName 'NerdctlTools'

            $NerdctlRepo = 'https://github.com/containerd/nerdctl/releases/download'
        }

        It "Should use defaults" {
            Install-Nerdctl

            Should -Invoke Uninstall-Nerdctl -ModuleName 'NerdctlTools' -Times 1 -Exactly -Scope It `
                -ParameterFilter { $Path -eq "$Env:ProgramFiles\Nerdctl" }
            Should -Invoke Get-InstallationFiles -ModuleName 'NerdctlTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "Nerdctl"
                        Uri          = "$NerdctlRepo/v7.9.8/nerdctl-7.9.8-windows-amd64.tar.gz"
                        Version      = '7.9.8'
                        DownloadPath = "$HOME\Downloads\nerdctl-7.9.8-windows-amd64.tar.gz"
                    }
                )
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'NerdctlTools' -ParameterFilter {
                $Feature -eq "Nerdctl"
                $InstallPath -eq "$Env:ProgramFiles\Nerdctl"
                $DownloadPath -eq "$HOME\Downloads\nerdctl-7.9.8-windows-amd64.tar.gz"
                $EnvPath -eq "$Env:ProgramFiles\Nerdctl\bin" 
                $cleanup -eq $true
            }
        }
        
        It "Should call function with user-specified values" {
            Install-Nerdctl -Version '1.2.3' -InstallPath 'TestDrive:\Nerdctl' -DownloadPath 'TestDrive:\Downloads'

            Should -Invoke Uninstall-Nerdctl -ModuleName 'NerdctlTools' `
                -ParameterFilter { $Path -eq 'TestDrive:\Nerdctl' }
            Should -Invoke Get-InstallationFiles -ModuleName 'NerdctlTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "Nerdctl"
                        Uri          = "$NerdctlRepo/v1.2.3/nerdctl-1.2.3-windows-amd64.tar.gz"
                        Version      = '1.2.3'
                        DownloadPath = "$HOME\Downloads"
                    }
                )
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'NerdctlTools' -ParameterFilter {
                $Feature -eq "Nerdctl"
                $InstallPath -eq 'TestDrive:\Nerdctl'
                $DownloadPath -eq 'TestDrive:\Downloads\nerdctl-1.2.3-windows-amd64.tar.gz'
                $EnvPath -eq 'TestDrive:\Nerdctl\bin'
                $cleanup -eq $true
            }
        }
    }

    Context "Uninstall-Nerdctl" -Tag "Uninstall-Nerdctl" {
        BeforeAll {
            Mock Get-DefaultInstallPath -ModuleName 'NerdctlTools' -MockWith { return 'TestDrive:\Program Files\Nerdctl' }
            Mock Test-EmptyDirectory -ModuleName 'NerdctlTools' -MockWith { return  $false }
            Mock Uninstall-ContainerToolConsent -ModuleName 'NerdctlTools' -MockWith { return $true }
            Mock Remove-Item -ModuleName 'NerdctlTools'
            Mock Remove-FeatureFromPath -ModuleName 'NerdctlTools'
        }

        It "Should successfully uninstall Nerdctl" {
            Mock Uninstall-NerdctlHelper -ModuleName 'NerdctlTools'

            Uninstall-Nerdctl -Path 'TestDrive:\Program Files\Nerdctl'

            Should -Invoke Uninstall-NerdctlHelper -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Nerdctl' }
        }

        It "Should successfully uninstall Nerdctl from default path" {
            Mock Uninstall-NerdctlHelper -ModuleName 'NerdctlTools'
            
            Uninstall-Nerdctl

            Should -Invoke Uninstall-NerdctlHelper -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Nerdctl' }
        }

        It "Should throw an error if user does not consent to uninstalling Nerdctl" {
            Mock Uninstall-ContainerToolConsent -ModuleName 'NerdctlTools' -MockWith { return $false }

            { Uninstall-Nerdctl -Path 'TestDrive:\Program Files\Nerdctl' } | Should -Throw 'Nerdctl uninstallation cancelled.'
        }
        
        It "Should do nothing if nerdctl is not installed at specified path" {
            Mock Test-EmptyDirectory -ModuleName 'NerdctlTools' -MockWith { return $true }

            Uninstall-Nerdctl
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "NerdctlTools"
            Should -Invoke Remove-FeatureFromPath -Times 0 -Scope It -ModuleName "NerdctlTools" 
        }

        It "Should successfully call uninstall Nerdctl helper function" {
            Uninstall-NerdctlHelper -Path 'TestDrive:\Program Files\Nerdctl'

            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Nerdctl' }
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Path -eq "$ENV:ProgramData\Nerdctl" }
            Should -Invoke Remove-FeatureFromPath -Times 1 -Scope It -ModuleName "NerdctlTools" `
                -ParameterFilter { $Feature -eq "nerdctl" }
        }

        It "Should write an error if nerdctl is not installed at specified path" {
            Mock Test-EmptyDirectory -ModuleName 'NerdctlTools' -MockWith { return $true }

            Uninstall-NerdctlHelper -Path 'TestDrive:\Program Files\Nerdctl'

            $Error[0].Exception.Message | Should -BeExactly 'Nerdctl does not exist at TestDrive:\Program Files\Nerdctl or the directory is empty.'
        }
    }
}
