###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

using module "..\containers-toolkit\Private\CommonToolUtilities.psm1"

Describe "BuildkitTools.psm1" {
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'Containers-Toolkit'
        Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\BuildkitTools.psm1" -Force

        $Script:commandError = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{
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

    BeforeEach {
        Remove-Item -Path "$TestDrive" -Re -Force -ErrorAction Ignore
    }

    AfterEach {
        $ENV:PESTER = $false
        Remove-Item -Path "$TestDrive" -Re -Force -ErrorAction Ignore
    }

    AfterAll {
        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\BuildkitTools.psm1" -Force -ErrorAction Ignore
    }

    Context "Install-Buildkit" -Tag "Install-Buildkit" {
        BeforeEach {
            $Script:BuildkitRepo = 'https://github.com/moby/buildkit/releases/download'
            $Script:TestDownloadPath = "$HOME\Downloads\buildkit-v1.0.0.windows-amd64.tar.gz"

            Mock Get-BuildkitLatestVersion -ModuleName 'BuildkitTools' -MockWith { return '1.0.0' }
            Mock Get-InstallationFile -ModuleName 'BuildkitTools' -MockWith { return $Script:TestDownloadPath }
            Mock Install-RequiredFeature -ModuleName 'BuildkitTools'
            Mock Register-BuildkitdService -ModuleName 'BuildkitTools'
            Mock Start-BuildkitdService -ModuleName 'BuildkitTools'
            Mock Uninstall-Buildkit -ModuleName "BuildkitTools"
            Mock Get-Command -ModuleName 'BuildkitTools'
            Mock Get-ChildItem -ModuleName 'BuildkitTools'
            Mock Test-EmptyDirectory  -ModuleName 'BuildkitTools' -MockWith { return $true }
            Mock Install-Buildkit -ModuleName 'BuildkitTools'
            Mock Remove-Item -ModuleName 'BuildkitTools'
        }

        AfterEach {
            Remove-Item -Path "TestDrive:\" -Force -ErrorAction Ignore
        }

        It 'Should not process on implicit request for validation (WhatIfPreference)' {
            {
                $WhatIfPreference = $true
                Install-Buildkit
            }
            Should -Invoke -CommandName Install-Buildkit -ModuleName 'BuildkitTools' -Exactly -Times 0 -Scope It
        }

        It 'Should not process on explicit request for validation (-WhatIf)' {
            { Install-Buildkit -WhatIf }
            Should -Invoke -CommandName Install-Buildkit -ModuleName 'BuildkitTools' -Exactly -Times 0 -Scope It
        }

        It "Should use defaults" {
            Install-Buildkit -Force -Confirm:$false

            Should -Invoke Uninstall-Buildkit -ModuleName 'BuildkitTools' -Times 0 -Exactly -Scope It
            Should -Invoke Get-InstallationFile -ModuleName 'BuildkitTools'  -ParameterFilter {
                $fileParameters[0].Feature -eq "Buildkit" -and
                $fileParameters[0].Repo -eq "moby/buildkit" -and
                $fileParameters[0].Version -eq 'latest' -and
                $fileParameters[0].DownloadPath -eq "$HOME\Downloads"
                $fileParameters[0].ChecksumSchemaFile -eq "$ModuleParentPath\Private\schemas\in-toto.sbom.schema.json" -and
                [string]::IsNullOrWhiteSpace($fileParameters.FileFilterRegEx)
            }

            Should -Invoke Install-RequiredFeature -ModuleName 'BuildkitTools' -ParameterFilter {
                $Feature -eq "Buildkit" -and
                $InstallPath -eq "$Env:ProgramFiles\Buildkit" -and
                $SourceFile -eq "$Script:TestDownloadPath" -and
                $EnvPath -eq "$Env:ProgramFiles\Buildkit\bin" -and
                $cleanup -eq $true
            }
            Should -Invoke Register-BuildkitdService -ModuleName 'BuildkitTools' -Times 0 -Exactly -Scope It
            Should -Invoke Start-BuildkitdService -ModuleName 'BuildkitTools' -Times 0 -Exactly -Scope It
        }

        It "Should call function with user-specified values" {
            $customPath = "TestDrive:\Downloads\buildkit-v0.2.3.windows-amd64.tar.gz"
            Mock Get-InstallationFile -ModuleName 'BuildkitTools' -MockWith { return $customPath }

            Install-Buildkit -Version '0.2.3' -InstallPath 'TestDrive:\BuildKit' -DownloadPath 'TestDrive:\Downloads' -OSArchitecture "arm64" -Force -Confirm:$false

            Should -Invoke Uninstall-Buildkit -ModuleName 'BuildkitTools' -Times 0 -Exactly -Scope It
            Should -Invoke Get-InstallationFile -ModuleName 'BuildkitTools' -ParameterFilter {
                $fileParameters[0].Version -eq '0.2.3'
                $fileParameters[0].OSArchitecture -eq 'arm64'
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'BuildkitTools' -ParameterFilter {
                $Feature -eq "Buildkit" -and
                $InstallPath -eq 'TestDrive:\BuildKit' -and
                $SourceFile -eq "$customPath" -and
                $EnvPath -eq 'TestDrive:\Buildkit\bin' -and
                $cleanup -eq $true
            }
        }

        It "Should setup Buildkitd service" {
            Mock Test-BuildkitdServiceExists -ModuleName 'BuildkitTools' -MockWith { return $true }

            Install-Buildkit -Setup -Force -Confirm:$false

            Should -Invoke Register-BuildkitdService -Times 1 -Exactly -Scope It -ModuleName 'BuildkitTools' `
                -ParameterFilter { $BuildKitPath -eq "$Env:ProgramFiles\Buildkit" -and $WinCNIPath -eq "" }
        }

        It "Should uninstall tool if it is already installed" {
            Mock Test-EmptyDirectory -ModuleName 'BuildkitTools' -MockWith { return $false }

            Install-Buildkit -Force -Confirm:$false

            Should -Invoke Uninstall-Buildkit -ModuleName 'BuildkitTools' -Times 1 -Exactly -Scope It `
                -ParameterFilter { $Path -eq "$Env:ProgramFiles\Buildkit" -and $force -eq $true }
        }

        It "Should throw an error if uninstallation fails" {
            Mock Test-EmptyDirectory -ModuleName 'BuildkitTools' -MockWith { return $false }
            Mock Uninstall-Buildkit -ModuleName 'BuildkitTools' -MockWith { throw 'Error' }

            { Install-Buildkit -Confirm:$false } | Should -Throw "Buildkit installation failed. Error"
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
            $MockBuildKitPath = "C:\Program Files\Buildkit"
            $expectedExecutablePath = "$MockBuildKitPath\bin\buildkitd.exe"

            Mock Test-Path -ModuleName "BuildkitTools" { return $true }
            Mock Add-MpPreference -ModuleName "BuildkitTools"
            Mock Test-EmptyDirectory -ModuleName "BuildkitTools" { return $false }
            Mock Get-DefaultInstallPath -ModuleName "BuildkitTools" `
                -MockWith { return $MockBuildKitPath } `
                -ParameterFilter { $Tool -eq "Buildkit" }
            Mock Get-DefaultInstallPath -ModuleName "BuildkitTools" `
                -MockWith { return "C:\Program Files\Containerd" } `
                -ParameterFilter { $Tool -eq "containerd" }

            $obj = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{ ExitCode = 0 }
            Mock Invoke-ExecutableCommand -ModuleName "BuildkitTools" -MockWith { return $obj }

            Mock Get-Service -ModuleName "BuildkitTools" -MockWith { return [MockService]::new('Buildkitd') }
            Mock Set-Service -ModuleName "BuildkitTools"
            Mock Start-BuildkitdService -ModuleName "BuildkitTools"
            Mock Test-ServiceRegistered -ModuleName 'BuildkitTools' -MockWith { return $false }
        }

        It "Should successfully register buildkitd service using defaults" {
            Register-BuildkitdService -Force

            # The default path for Buildkit is $Env:ProgramFiles\Buildkit.
            # Since tests are run as a user (not as admin), it is not possible to create a conf file in the default path.
            $expectedCommandArguments = "--register-service --debug --containerd-worker=true --service-name buildkitd"

            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "BuildkitTools" -ParameterFilter {
                ($Executable -eq $expectedExecutablePath ) -and
                ($Arguments -eq $expectedCommandArguments)
            }
            Should -Invoke Start-BuildkitdService -Times 0 -Scope It -ModuleName "BuildkitTools"
        }

        It "Should successfully register buildkitd service using custom values" {
            # Create mock .conf file
            $MockWinCNIPath = "$TestDrive\Program Files\Containerd\cni"
            $MockCniBinDir = "$MockWinCNIPath\bin"
            $MockCniConfDir = "$MockWinCNIPath\conf"
            $MockCniConfPath = "$MockCniConfDir\0-containerd-nat.conf"
            New-Item -Path "$MockCniConfDir" -ItemType 'Directory' -Force | Out-Null
            Set-Content -Path "$MockCniConfPath" -Value 'Nat config data here' -Force

            Register-BuildkitdService -WinCNIPath $MockWinCNIPath -BuildKitPath $MockBuildKitPath -Start -Force

            $expectedExecutablePath = "$MockBuildKitPath\bin\buildkitd.exe"
            $expectedCommandArguments = "--register-service --debug --containerd-worker=true --containerd-cni-config-path=`"$MockCniConfPath`" --containerd-cni-binary-dir=`"$MockCniBinDir`" --service-name buildkitd"
            Write-Host "'$expectedCommandArguments'" -ForegroundColor Magenta
            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter {
                    ($Executable -eq $expectedExecutablePath ) -and
                    ($Arguments -eq $expectedCommandArguments)
            }
            Should -Invoke Start-BuildkitdService -Times 1 -Scope It -ModuleName "BuildkitTools"
        }

        # FIXME: This test is failing we are not able mock $PSCmdlet.ShouldContinue
        It "Should log an error and stop execution if user does not consent" -Skip {
            $mockedConsent = [ActionConsent]::No.value__
            Mock Test-ConfFileEmpty -ModuleName "BuildkitTools" { return $true }
            Mock Get-ConsentToRegisterBuildkit -ModuleName "BuildkitTools" { return $mockedConsent }

            $ENV:PESTER = $true
            Register-BuildkitdService
            $Error[0].Exception.Message | Should -BeExactly  "buildkitd service registration cancelled."
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

            Register-BuildkitdService -WinCNIPath $MockWinCNIPath -BuildKitPath $MockBuildKitPath -Start -Force

            $expectedCommandArguments = '--register-service --debug --containerd-worker=true --service-name buildkitd'
            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter {
                    ($Executable -eq $expectedExecutablePath ) -and
                ($Arguments -eq $expectedCommandArguments)
            }
        }

        It "Should throw an error if user does not consent to registering buildkitd service without NAT conf file" {
            $mockedConsent = [ActionConsent]::No.value__
            Mock Test-ConfFileEmpty -ModuleName "BuildkitTools" { return $true }
            Mock Get-ConsentToRegisterBuildkit -ModuleName "BuildkitTools" { return $mockedConsent }

            $ENV:PESTER = $true
            { Register-BuildkitdService -WinCNIPath "$TestDrive\SomeOtherFolder" } | Should -Throw "Failed to register buildkit service.*"
        }

        It "Should throw an error if service registration fails" {
            Mock Invoke-ExecutableCommand -ModuleName "BuildkitTools" -MockWith { return $Script:commandError }

            { Register-BuildkitdService -Force } | Should -Throw "Failed to register buildkitd service.*"
        }

        It "Should throw an error if service is not found" {
            Mock Get-Service -ModuleName "BuildkitTools"

            { Register-BuildkitdService -Force } | Should -Throw "Failed to register buildkitd service.*"
        }

        It "Should throw an error if could not set containerd dependency" {
            Mock Invoke-ExecutableCommand -ModuleName "BuildkitTools" -MockWith { return $Script:commandError } -ParameterFilter { $Executable -eq 'sc.exe' }

            Register-BuildkitdService -Force

            $Error[0].Exception.Message | Should -Match "Failed to set dependency for buildkitd on containerd."
        }
    }

    Context "Uninstall-Buildkit" -Tag "Uninstall-Buildkit" {
        BeforeAll {
            Mock Get-DefaultInstallPath -ModuleName 'BuildkitTools' -MockWith { return 'TestDrive:\Program Files\Buildkit' }
            Mock Test-EmptyDirectory -ModuleName 'BuildkitTools' -MockWith { return  $false }
            Mock Stop-BuildkitdService -ModuleName 'BuildkitTools'
            Mock Unregister-Buildkitd -ModuleName 'BuildkitTools'
            Mock Remove-Item -ModuleName 'BuildkitTools'
            Mock Remove-FeatureFromPath -ModuleName 'BuildkitTools'
            Mock Uninstall-ProgramFiles -ModuleName 'BuildkitTools'
        }

        It "Should successfully uninstall Buildkit" {
            Uninstall-Buildkit -Path 'TestDrive:\Custom\Buildkit\' -Confirm:$false -Force

            # Should stop and deregister the buildkitd service
            Should -Invoke Stop-BuildkitdService -Times 1 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Unregister-Buildkitd -Times 1 -Scope It -ModuleName "BuildkitTools"

            # Should remove buildkit dir
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Custom\Buildkit\bin' }

            # Should not purge program data
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\buildkit' }
            Should -Invoke Uninstall-ProgramFiles -Times 0 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq "$ENV:ProgramData\Buildkit" }
            Should -Invoke Remove-FeatureFromPath -Times 0 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Feature -eq "buildkit" }
        }

        It "Should successfully uninstall Buildkit from default path" {
            Uninstall-Buildkit -Confirm:$false -Force

            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Buildkit\bin' }
        }

        It "Should successfully purge program data" {
            Uninstall-Buildkit -Path 'TestDrive:\Program Files\Buildkit' -Confirm:$false -Force -Purge

            # Should purge program data
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Buildkit' }
            Should -Invoke Uninstall-ProgramFiles -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Path -eq "$ENV:ProgramData\Buildkit" }
            Should -Invoke Remove-FeatureFromPath -Times 1 -Scope It -ModuleName "BuildkitTools" `
                -ParameterFilter { $Feature -eq "buildkit" }
        }

        It "Should do nothing if user does not consent to uninstalling Buildkit" {
            $ENV:PESTER = $true
            Uninstall-Buildkit -Path 'TestDrive:\Program Files\Buildkit' -Confirm:$false -Force:$false

            # Should NOT stop and deregister the buildkit service
            Should -Invoke Stop-BuildkitdService -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Unregister-Buildkitd -Times 0 -Scope It -ModuleName "BuildkitTools"

            # Should NOT remove buildkit binaries/dir
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "BuildkitTools"
        }

        It "Should do nothing if buildkit is not installed at specified path" {
            Mock Test-EmptyDirectory -ModuleName 'BuildkitTools' -MockWith { return $true }

            Uninstall-Buildkit -Path 'TestDrive:\Program Files\Buildkit' -Confirm:$false

            Should -Invoke Stop-BuildkitdService -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Unregister-Buildkitd -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "BuildkitTools"
        }

        It "Should throw an error if buildkitd service stop or unregister was unsuccessful" {
            Mock Stop-BuildkitdService -ModuleName 'BuildkitTools' -MockWith { Throw 'Error' }

            { Uninstall-Buildkit -Path 'TestDrive:\Program Files\Buildkit' -Confirm:$false -Force -Purge } | Should -Throw "*Could not stop or unregister buildkitd service.*"
            Should -Invoke Unregister-Buildkitd -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "BuildkitTools"
            Should -Invoke Remove-FeatureFromPath -Times 0 -Scope It -ModuleName "BuildkitTools"
        }
    }
}
