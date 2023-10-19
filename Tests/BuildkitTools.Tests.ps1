Describe "BuildkitTools.psm1" {
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'ContainerToolsForWindows'
        Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\BuildkitTools.psm1" -Force

        $commandError = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{ 
            ExitCode       = 1
            StandardError  = New-MockObject -Type 'System.IO.StreamReader' -Methods @{ 
                ReadToEnd = { return "Error message" } 
            }
            StandardOutput = New-MockObject -Type 'System.IO.StreamReader' -Methods @{ 
                ReadToEnd = { return "Sample command output" } 
            }
        }

        # Mock functions
        function Test-ServiceRegistered { }
        Mock Test-ServiceRegistered -ModuleName 'BuildkitTools' -MockWith { return $true }
    }

    AfterAll {
        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\BuildkitTools.psm1" -Force -ErrorAction Ignore
    }

    Context "Install-Buildkit" -Tag "Install-Buildkit" {
        BeforeAll {
            Mock Get-BuildkitLatestVersion { return '1.0.0' } -ModuleName 'BuildkitTools'
            Mock Get-InstallationFiles -ModuleName 'BuildkitTools'
            Mock Install-RequiredFeature -ModuleName 'BuildkitTools'
            Mock Register-BuildkitdService -ModuleName 'BuildkitTools'
            Mock Start-BuildkitdService -ModuleName 'BuildkitTools'
            Mock Uninstall-Buildkit -ModuleName "BuildkitTools"
            Mock Get-Command -ModuleName 'BuildkitTools'
            Mock Get-ChildItem -ModuleName 'BuildkitTools'

            $BuildkitRepo = 'https://github.com/moby/buildkit/releases/download'
        }

        It "Should use defaults" {
            Install-Buildkit

            Should -Invoke Uninstall-Buildkit -ModuleName 'BuildkitTools' -Times 1 -Exactly -Scope It `
                -ParameterFilter { $Path -eq "$Env:ProgramFiles\Buildkit" }
            Should -Invoke Get-InstallationFiles -ModuleName 'BuildkitTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "Buildkit"
                        Uri          = "$BuildkitRepo/v1.0.0/buildkit-v1.0.0.windows-amd64.tar.gz"
                        Version      = '1.0.0'
                        DownloadPath = "$HOME\Downloads\buildkit-v1.0.0.windows-amd64.tar.gz"
                    }
                )
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'BuildkitTools' -ParameterFilter {
                $Feature -eq "Buildkit"
                $InstallPath -eq "$Env:ProgramFiles\Buildkit" -and
                $DownloadPath -eq "$HOME\Downloads\buildkit-v1.0.0.windows-amd64.tar.gz"
                $EnvPath -eq "$Env:ProgramFiles\Buildkit\bin"
                $cleanup -eq $true
            }
            Should -Invoke Register-BuildkitdService -ModuleName 'BuildkitTools' -Times 0 -Exactly -Scope It
            Should -Invoke Start-BuildkitdService -ModuleName 'BuildkitTools' -Times 0 -Exactly -Scope It
        }
        
        It "Should call function with user-specified values" {
            Install-Buildkit -Version '0.2.3' -InstallPath 'TestDrive:\BuildKit' -DownloadPath 'TestDrive:\Downloads'

            Should -Invoke Uninstall-Buildkit -ModuleName 'BuildkitTools' `
                -ParameterFilter { $Path -eq 'TestDrive:\BuildKit' }
            Should -Invoke Get-InstallationFiles -ModuleName 'BuildkitTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "Buildkit"
                        Uri          = "$BuildkitRepo/v0.2.3/buildkit-v0.2.3.windows-amd64.tar.gz"
                        Version      = '0.2.3'
                        DownloadPath = "$HOME\Downloads"
                    }
                )
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'BuildkitTools' -ParameterFilter {
                $Feature -eq "Buildkit"
                $InstallPath -eq 'TestDrive:\BuildKit' -and
                $DownloadPath -eq 'TestDrive:\Downloads\buildkit-v0.2.3.windows-amd64.tar.gz'
                $EnvPath -eq 'TestDrive:\Buildkit\bin'
                $cleanup -eq $true
            }
        }

        It "Should setup Buildkitd service" {
            Mock Test-BuildkitdServiceExists -ModuleName 'BuildkitTools' -MockWith { return $true }

            Install-Buildkit -Setup

            Should -Invoke Register-BuildkitdService -Times 1 -Exactly -Scope It -ModuleName 'BuildkitTools' `
                -ParameterFilter { $BuildKitPath -eq "$Env:ProgramFiles\Buildkit" -and $WinCNIPath -eq "" }
            Should -Invoke Start-BuildkitdService -Times 1 -Exactly -Scope It -ModuleName 'BuildkitTools'
        }
    }
    
    Context "Service action" -Tag "Service action" {
        BeforeAll {
            Mock Invoke-ServiceAction -ModuleName 'BuildkitTools' -MockWith { }
        }

        It "Should call Invoke-ServiceAction to start Buildkitd service" {
            Start-BuildkitdService

            Should -Invoke Invoke-ServiceAction -ModuleName 'BuildkitTools' -ParameterFilter { $Service -eq "Buildkitd" -and $Action -eq 'Start' }
        }

        It "Should call Invoke-ServiceAction to stop Buildkitd service" {
            Stop-BuildkitdService

            Should -Invoke Invoke-ServiceAction -ModuleName 'BuildkitTools' -ParameterFilter { $Service -eq "Buildkitd" -and $Action -eq 'Stop' }
        }
    }
    
    Context "Register-BuildkitdService" -Tag "Register-BuildkitdService" {
        BeforeAll {
            $MockBuildKitPath = "$TestDrive\Program Files\Buildkit"
            New-Item -Path "$MockBuildKitPath\bin\buildkitd.exe" -ItemType 'File' -Force | Out-Null
            New-Item -Path 'TestDrive:\Program Files\Containerd\cni\conf' -ItemType 'Directory' -Force | Out-Null
            Set-Content -Path "TestDrive:\Program Files\Containerd\cni\conf\0-containerd-nat.conf" -Value 'Nat config data here' -Force

            Mock Test-Path -ModuleName "BuildkitTools" { return $true }
            Mock Add-MpPreference -ModuleName "BuildkitTools"
            Mock Test-EmptyDirectory -ModuleName "BuildkitTools" { return $false }
            Mock Get-DefaultInstallPath -ModuleName "BuildkitTools" `
                -MockWith { return $MockBuildKitPath } `
                -ParameterFilter { $Tool -eq "Buildkit" }
            Mock Get-DefaultInstallPath -ModuleName "BuildkitTools" `
                -MockWith { return "$TestDrive\Program Files\Containerd" } `
                -ParameterFilter { $Tool -eq "containerd" }
                
            $obj = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{ ExitCode = 0 }
            Mock Invoke-ExecutableCommand -ModuleName "BuildkitTools" -MockWith { return $obj }

            # $MockService = New-MockObject -Type System.ServiceProcess.ServiceController -Methods @{ WaitForStatus = { } }
            # Mock Get-Service -ModuleName "BuildkitTools" -MockWith { return $MockService }
            Mock Get-Service -ModuleName "BuildkitTools" -MockWith { return [MockService]::new('Buildkitd') }
            Mock Set-Service -ModuleName "BuildkitTools"
            Mock Start-BuildkitdService -ModuleName "BuildkitTools"
        }

        AfterAll {
            Get-ChildItem -Path 'TestDrive:\' | Remove-Item -Recurse -Force
        }
        
        It "Should successfully register buildkitd service using defaults" {
            $MockWinCNIPath = "$TestDrive\Program Files\Containerd\cni"
            $MockCniBinDir = "$MockWinCNIPath\bin"
            $MockCniConfPath = "$MockWinCNIPath\conf\0-containerd-nat.conf"

            Register-BuildkitdService

            $expectedExecutablePath = "$TestDrive\Program Files\buildkit\bin\buildkitd.exe"
            $expectedCommandArguments = "--register-service --debug --containerd-worker=true --containerd-cni-config-path=`"$MockCniConfPath`" --containerd-cni-binary-dir=`"$MockCniBinDir`" --service-name buildkitd"

            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { ($Executable -eq $expectedExecutablePath ) -and ($Arguments -eq $expectedCommandArguments) }
            Should -Invoke Start-BuildkitdService -Times 0 -Scope It -ModuleName "BuildkitTools"
        }
        
        It "Should successfully register buildkitd service using custom values" {
            $MockWinCNIPath = "$TestDrive\Program Files\Containerd\cni"
            $MockCniBinDir = "$MockWinCNIPath\bin"
            $MockCniConfPath = "$TestDrive\Program Files\Containerd\cni\conf\0-containerd-nat.conf"

            Register-BuildkitdService -WinCNIPath $MockWinCNIPath -BuildKitPath $MockBuildKitPath -Start

            $expectedExecutablePath = "$MockBuildKitPath\bin\buildkitd.exe"
            $expectedCommandArguments = "--register-service --debug --containerd-worker=true --containerd-cni-config-path=`"$MockCniConfPath`" --containerd-cni-binary-dir=`"$MockCniBinDir`" --service-name buildkitd"
            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { ($Executable -eq $expectedExecutablePath ) -and ($Arguments -eq $expectedCommandArguments) }
            Should -Invoke Start-BuildkitdService -Times 1 -Scope It -ModuleName "BuildkitTools"
        }

        It "Should throw an error if Buildkit is not installed at the specified path" {
            Mock Test-EmptyDirectory -ModuleName "BuildkitTools" { return $true }
            
            { Register-BuildkitdService } | Should -Throw "Buildkit does not exist at $MockBuildKitPath or the directory is empty"
        }

        It "Should throw an error if Buildkitd service does not exist" {
            Mock Test-Path -ModuleName "BuildkitTools" { return $false }
            Mock Get-Command -ModuleName "BuildkitTools"

            Register-BuildkitdService
            $Error[0].Exception.Message | Should -BeLike 'Buildkitd executable not installed.'
            Should -Invoke Invoke-ExecutableCommand -Times 0 -Scope It -ModuleName "BuildkitTools"
        }
        
        It "Should show warning if user consents to registering buildkitd service without NAT conf file" {
            $yesValue = [ActionConsent]::Yes.value__
            Mock Test-ConfFileEmpty -ModuleName "BuildkitTools" { return $true }
            Mock Get-ConsentToRegisterBuildkit -ModuleName "BuildkitTools" { return $yesValue }

            Register-BuildkitdService -WinCNIPath "$TestDrive\SomeOtherFolder"

            $expectedExecutablePath = "$MockBuildKitPath\bin\buildkitd.exe"
            $expectedCommandArguments = '--register-service --debug --containerd-worker=true --service-name buildkitd'
            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { ($Executable -eq $expectedExecutablePath ) -and ($Arguments -eq $expectedCommandArguments) }
        }
        
        It "Should throw an error if user does not consent to registering buildkitd service without NAT conf file" {
            $mockedConsent = [ActionConsent]::No.value__
            Mock Test-ConfFileEmpty -ModuleName "BuildkitTools" { return $true }
            Mock Get-ConsentToRegisterBuildkit -ModuleName "BuildkitTools" { return $mockedConsent }

            { Register-BuildkitdService -WinCNIPath "$TestDrive\SomeOtherFolder" } | Should -Throw "Failed to register buildkit service.*"
        }
        
        It "Should throw an error if service registration fails" {
            Mock Invoke-ExecutableCommand -ModuleName "BuildkitTools" -MockWith { return $commandError }

            { Register-BuildkitdService } | Should -Throw "Failed to register buildkitd service.*"
        }
        
        It "Should throw an error if service is not found" {
            Mock Get-Service -ModuleName "BuildkitTools"

            { Register-BuildkitdService } | Should -Throw "Failed to register buildkitd service.*"
        }
        
        It "Should throw an error if could not set containerd dependency" {
            Mock Invoke-ExecutableCommand -ModuleName "BuildkitTools" -MockWith { return $commandError } -ParameterFilter { $Executable -eq 'sc.exe' }

            Register-BuildkitdService

            $Error[0].Exception.Message | Should -Match "Failed to set dependency for buildkitd on containerd."
        }
    }
    
    Context "Uninstall-Buildkit" -Tag "Uninstall-Buildkit" {
        BeforeAll {
            Mock Get-DefaultInstallPath -ModuleName 'BuildkitTools' -MockWith { return 'TestDrive:\Program Files\Buildkit' }
            Mock Test-EmptyDirectory -ModuleName 'BuildkitTools' -MockWith { return  $false }
            Mock Uninstall-ContainerToolConsent -ModuleName 'BuildkitTools' -MockWith { return $true }
            Mock Stop-BuildkitdService -ModuleName 'BuildkitTools'
            Mock Unregister-Buildkitd -ModuleName 'BuildkitTools'
            Mock Remove-Item -ModuleName 'BuildkitTools'
            Mock Remove-FeatureFromPath -ModuleName 'BuildkitTools'
        }

        It "Should successfully uninstall Buildkit" {
            Mock Uninstall-BuildkitHelper -ModuleName 'BuildkitTools'

            Uninstall-Buildkit -Path 'TestDrive:\Program Files\Buildkit'

            Should -Invoke Uninstall-BuildkitHelper -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Buildkit' }
        }

        It "Should successfully uninstall Buildkit from default path" {
            Mock Uninstall-BuildkitHelper -ModuleName 'BuildkitTools'

            Uninstall-Buildkit

            Should -Invoke Uninstall-BuildkitHelper -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Buildkit' }
        }

        It "Should throw an error if user does not consent to uninstalling Buildkit" {
            Mock Uninstall-ContainerToolConsent -ModuleName 'BuildkitTools' -MockWith { return $false }

            { Uninstall-Buildkit -Path 'TestDrive:\Program Files\Buildkit' } | Should -Throw "Buildkit uninstallation cancelled."
        }

        It "Should successfully call uninstall Buildkit helper function" {
            Uninstall-BuildkitHelper -Path 'TestDrive:\Program Files\Buildkit'

            Should -Invoke Stop-BuildkitdService -Times 1 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Unregister-Buildkitd -Times 1 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\buildkit' }
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Buildkit' }
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq "$ENV:ProgramData\Buildkit" }
            Should -Invoke Remove-FeatureFromPath -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Feature -eq "buildkit" }
        }
        
        It "Should do nothing if buildkit is not installed at specified path" {
            Mock Test-EmptyDirectory -ModuleName 'BuildkitTools' -MockWith { return $true }

            Uninstall-BuildkitHelper -Path 'TestDrive:\Program Files\Buildkit'

            Should -Invoke Stop-BuildkitdService -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Unregister-Buildkitd -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Remove-FeatureFromPath -Times 0 -Scope It -ModuleName "BuildkitTools"
            
            $Error[0].Exception.Message | Should -BeExactly 'Buildkit does not exist at TestDrive:\Program Files\Buildkit or the directory is empty.'
        }
        
        It "Should throw an error if buildkitd service stop or unregister was unsuccessful" {
            Mock Stop-BuildkitdService -ModuleName 'BuildkitTools' -MockWith { Throw 'Error' }

            { Uninstall-BuildkitHelper -Path 'TestDrive:\Program Files\Buildkit' } | Should -Throw "Could not stop or unregister buildkitd service.*"
            Should -Invoke Unregister-Buildkitd -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Remove-FeatureFromPath -Times 0 -Scope It -ModuleName "BuildkitTools" 
        }
    }
}