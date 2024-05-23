###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


Describe "ContainerdTools.psm1" {
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'Containers-Toolkit'
        Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Public\ContainerdTools.psm1" -Force

        # Mock objects
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
        Mock Test-ServiceRegistered -ModuleName 'ContainerdTools' -MockWith { return $true }
    }

    AfterEach {
        $ENV:PESTER = $false
    }

    AfterAll {
        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\ContainerdTools.psm1" -Force -ErrorAction Ignore
    }

    Context "Install-Containerd" -Tag "Install-Containerd" {
        BeforeAll {
            Mock Get-ContainerdLatestVersion { return '1.0.0' } -ModuleName 'ContainerdTools'
            Mock Get-InstallationFile -ModuleName 'ContainerdTools'
            Mock Install-RequiredFeature -ModuleName 'ContainerdTools'
            Mock Uninstall-Containerd -ModuleName "ContainerdTools"
            Mock Register-ContainerdService -ModuleName 'ContainerdTools'
            Mock Start-ContainerdService -ModuleName 'ContainerdTools'
            Mock Get-Command -ModuleName 'ContainerdTools'
            Mock Get-ChildItem -ModuleName 'ContainerdTools'
            Mock Test-EmptyDirectory  -ModuleName 'ContainerdTools' -MockWith { return $true }
            Mock Install-ContainerToolConsent -ModuleName 'ContainerdTools' -MockWith { return $true }
            Mock Install-Containerd -ModuleName 'ContainerdTools'

            $Script:ContainerdRepo = 'https://github.com/containerd/containerd/releases/download'
        }

        It 'Should not process on implicit request for validation (WhatIfPreference)' {
            {
                $WhatIfPreference = $true
                Install-Containerd
            }
            Should -Invoke -CommandName Install-Containerd -ModuleName 'ContainerdTools' -Exactly -Times 0 -Scope It
        }

        It 'Should not process on explicit request for validation (-WhatIf)' {
            { Install-Containerd -WhatIf }
            Should -Invoke -CommandName Install-Containerd -ModuleName 'ContainerdTools' -Exactly -Times 0 -Scope It
        }

        It "Should use defaults" {
            Install-Containerd -Force -Confirm:$false

            Should -Invoke Uninstall-Containerd -ModuleName 'ContainerdTools' -Times 0 -Exactly -Scope It
            Should -Invoke Get-InstallationFile -ModuleName 'ContainerdTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "Containerd"
                        Uri          = "$Script:ContainerdRepo/v1.0.0/containerd-1.0.0-windows-amd64.tar.gz"
                        Version      = '1.0.0'
                        DownloadPath = "$HOME\Downloads\containerd-1.0.0-windows-amd64.tar.gz"
                    }
                )
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'ContainerdTools' -ParameterFilter {
                $Feature -eq "Containerd"
                $InstallPath -eq "$Env:ProgramFiles\Containerd" -and
                $DownloadPath -eq "$HOME\Downloads\containerd-1.0.0-windows-amd64.tar.gz"
                $EnvPath -eq "$Env:ProgramFiles\Containerd\bin"
                $cleanup -eq $true
            }

            Should -Invoke Register-ContainerdService -ModuleName 'ContainerdTools' -Times 0 -Exactly -Scope It
            Should -Invoke Start-ContainerdService -ModuleName 'ContainerdTools' -Times 0 -Exactly -Scope It
        }

        It "Should call function with user-specified values" {
            Install-Containerd -Version '1.2.3' -InstallPath 'TestDrive:\Containerd' -DownloadPath 'TestDrive:\Downloads' -Force -Confirm:$false

            Should -Invoke Uninstall-Containerd -ModuleName 'ContainerdTools' -Times 0 -Exactly -Scope It
            Should -Invoke Get-InstallationFile -ModuleName 'ContainerdTools' -ParameterFilter {
                $Files -like @(
                    @{
                        Feature      = "Containerd"
                        Uri          = "$Script:ContainerdRepo/v1.2.3/containerd-1.2.3-windows-amd64.tar.gz"
                        Version      = '1.2.3'
                        DownloadPath = "$HOME\Downloads"
                    }
                )
            }
            Should -Invoke Install-RequiredFeature -ModuleName 'ContainerdTools' -ParameterFilter {
                $Feature -eq "Containerd"
                $InstallPath -eq 'TestDrive:\Containerd' -and
                $DownloadPath -eq 'TestDrive:\Downloads\containerd-1.2.3-windows-amd64.tar.gz'
                $EnvPath -eq 'TestDrive:\Containerd\bin'
                $cleanup -eq $true
            }
        }

        It "Should setup Containerd service" {
            Install-Containerd -Setup -Force -Confirm:$false

            Should -Invoke Register-ContainerdService -Times 1 -Exactly -Scope It -ModuleName 'ContainerdTools' `
                -ParameterFilter { $ContainerdPath -eq "$Env:ProgramFiles\Containerd" }
        }

        It "Should uninstall tool if it is already installed" {
            Mock Test-EmptyDirectory -ModuleName 'ContainerdTools' -MockWith { return $false }

            Install-Containerd -Force -Confirm:$false

            Should -Invoke Uninstall-Containerd -ModuleName 'ContainerdTools' -Times 1 -Exactly -Scope It `
                -ParameterFilter { $Path -eq "$Env:ProgramFiles\Containerd" -and $force -eq $true }
        }

        It "Should throw an error if uninstallation fails" {
            Mock Test-EmptyDirectory -ModuleName 'ContainerdTools' -MockWith { return $false }
            Mock Uninstall-Containerd -ModuleName 'ContainerdTools' -MockWith { throw 'Error' }

            { Install-Containerd -Confirm:$false } | Should -Throw "Containerd installation failed. Error"
        }
    }

    Context "Service action" -Tag "Service action" {
        BeforeAll {
            Mock Invoke-ServiceAction -ModuleName 'ContainerdTools' -MockWith { }
        }

        It "Should call Invoke-ServiceAction to start Containerd service" {
            Start-ContainerdService

            Should -Invoke Invoke-ServiceAction -ModuleName 'ContainerdTools' -ParameterFilter { $Service -eq "Containerd" -and $Action -eq 'Start' }
        }

        It "Should call Invoke-ServiceAction to stop Containerd service" {
            Stop-ContainerdService

            Should -Invoke Invoke-ServiceAction -ModuleName 'ContainerdTools' -ParameterFilter { $Service -eq "Containerd" -and $Action -eq 'Stop' }
        }
    }

    Context "Register-ContainerdService" -Tag "Register-ContainerdService" {
        BeforeAll {
            $MockContainerdPath = "$TestDrive\Program Files\Containerd"
            # New-Item -Path $MockContainerdPath -ItemType 'Directory' -Force | Out-Null
            New-Item -Path "$MockContainerdPath\bin\containerd.exe" -ItemType 'File' -Force | Out-Null

            Mock Test-Path -ModuleName "ContainerdTools" { return $true }
            Mock Test-EmptyDirectory -ModuleName "ContainerdTools" { return $false }
            Mock Add-MpPreference -ModuleName "ContainerdTools"
            Mock Get-DefaultInstallPath -ModuleName "ContainerdTools" `
                -MockWith { return $MockContainerdPath } `
                -ParameterFilter { $Tool -eq "Containerd" }

            $mockProcess = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{ ExitCode = 0 }
            Mock Invoke-ExecutableCommand -ModuleName "ContainerdTools" -MockWith { return $mockProcess }

            # Mock for default config
            $mockConfigStdOut = New-MockObject -Type 'System.IO.StreamReader' -Methods @{ ReadToEnd = { return "Sample containerd default config data" } }
            $mockConfigProcess = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{ 
                StandardOutput = $mockConfigStdOut 
            }
            Mock Invoke-ExecutableCommand -ModuleName "ContainerdTools" `
                -ParameterFilter { $Arguments -eq "config default" } `
                -MockWith { return $mockConfigProcess }
           
            Mock Get-Service -ModuleName "ContainerdTools" -MockWith { return [MockService]::new('Containerd') }
            Mock Set-Service -ModuleName "ContainerdTools"
            Mock Start-ContainerdService -ModuleName "ContainerdTools"
            Mock Test-ServiceRegistered -ModuleName 'ContainerdTools' -MockWith { return $false }
        }

        AfterAll {
            Get-ChildItem -Path 'TestDrive:\' | Remove-Item -Recurse -Force
        }

        It "Should successfully register containerd service using default values" {
            Register-ContainerdService -Force

            $expectedExecutablePath = "$MockContainerdPath\bin\containerd.exe"

            Should -Invoke Invoke-ExecutableCommand -ModuleName "ContainerdTools" `
                -ParameterFilter { ($Executable -eq $expectedExecutablePath ) -and ($Arguments -eq "config default") }

            "$MockContainerdPath\config.toml" | Should -Exist
            "$MockContainerdPath\config.toml" | Should -FileContentMatch 'Sample containerd default config data'

            $expectedCommandArguments = "--register-service --log-level debug --service-name containerd --log-file `"$env:TEMP\containerd.log`""
            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "ContainerdTools" `
                -ParameterFilter { ($Executable -eq $expectedExecutablePath ) -and ($Arguments -eq $expectedCommandArguments) }

            Should -Invoke Set-Service -ModuleName "ContainerdTools" `
                -ParameterFilter { $name -eq "containerd" -and $StartupType -eq "Automatic" }
            Should -Invoke Start-ContainerdService -Times 0 -Scope It -ModuleName "ContainerdTools"
        }

        It "Should successfully register containerd service using custom values" {
            Register-ContainerdService -ContainerdPath $MockContainerdPath -Start -Force

            $expectedExecutablePath = "$MockContainerdPath\bin\containerd.exe"

            Should -Invoke Invoke-ExecutableCommand -ModuleName "ContainerdTools" `
                -ParameterFilter { ($Executable -eq $expectedExecutablePath ) -and ($Arguments -eq "config default") }

            "$MockContainerdPath\config.toml" | Should -Exist
            "$MockContainerdPath\config.toml" | Should -FileContentMatch 'Sample containerd default config data'

            $expectedCommandArguments = "--register-service --log-level debug --service-name containerd --log-file `"$env:TEMP\containerd.log`""
            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "ContainerdTools" `
                -ParameterFilter { ($Executable -eq $expectedExecutablePath ) -and ($Arguments -eq $expectedCommandArguments) }

            Should -Invoke Set-Service -ModuleName "ContainerdTools" `
                -ParameterFilter { $name -eq "containerd" -and $StartupType -eq "Automatic" }
            Should -Invoke Start-ContainerdService -Times 1 -Scope It -ModuleName "ContainerdTools"
        }

        It "Should log an error and stop execution if user does not consent" {
            $ENV:PESTER = $true
            Register-ContainerdService
            $Error[0].Exception.Message | Should -BeExactly  "containerd service registration cancelled."
        }

        It "Should throw an error if Containerd is not installed at the specified path" {
            Mock Test-EmptyDirectory -ModuleName "ContainerdTools" { return $true }

            { Register-ContainerdService } | Should -Throw "Containerd does not exist at $MockContainerdPath or the directory is empty"
        }

        It "Should throw an error if service registration fails" {
            Mock Invoke-ExecutableCommand -ModuleName "ContainerdTools" -MockWith { return $Script:commandError }

            { Register-ContainerdService -Force } | Should -Throw "Failed to register containerd service.*"
        }

        It "Should throw an error if service is not found after registration is complete" {
            Mock Get-Service -ModuleName "ContainerdTools"

            { Register-ContainerdService -Force } | Should -Throw "Failed to register containerd service.*"
        }

        It "Should throw an error if config file is empty" {
            # Mock for default config
            $mockConfigStdOut = New-MockObject -Type 'System.IO.StreamReader' -Methods @{ ReadToEnd = { return } }
            $mockConfigProcess = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{ 
                StandardOutput = $mockConfigStdOut 
            }
            Mock Invoke-ExecutableCommand -ModuleName "ContainerdTools" `
                -ParameterFilter { $Arguments -eq "config default" } `
                -MockWith { return $mockConfigProcess }

            { Register-ContainerdService -Force } | Should -Throw "Config file is empty. '$MockContainerdPath\config.toml'"
        }
    }

    Context "Uninstall-Containerd" -Tag "Uninstall-Containerd" {
        BeforeAll {
            Mock Get-DefaultInstallPath -ModuleName 'ContainerdTools' -MockWith { return 'TestDrive:\Program Files\Containerd' }
            Mock Test-EmptyDirectory -ModuleName 'ContainerdTools' -MockWith { return  $false }
            Mock Uninstall-ContainerToolConsent -ModuleName 'ContainerdTools' -MockWith { return $true }
            Mock Stop-ContainerdService -ModuleName 'ContainerdTools'
            Mock Unregister-Containerd -ModuleName 'ContainerdTools'
            Mock Remove-Item -ModuleName 'ContainerdTools'
            Mock Remove-FeatureFromPath -ModuleName 'ContainerdTools'
        }

        It "Should successfully uninstall Containerd" {
            Mock Uninstall-ContainerdHelper -ModuleName 'ContainerdTools'

            Uninstall-Containerd -Path 'TestDrive:\Program Files\Containerd' -Confirm:$false -Force

            Should -Invoke Uninstall-ContainerdHelper -Times 1 -Scope It -ModuleName "ContainerdTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Containerd' }
        }

        It "Should successfully uninstall Containerd from default path" {
            Mock Uninstall-ContainerdHelper -ModuleName 'ContainerdTools'

            Uninstall-Containerd -Confirm:$false -Force

            Should -Invoke Uninstall-ContainerdHelper -Times 1 -Scope It -ModuleName "ContainerdTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Containerd' }
        }

        It "Should throw an error if user does not consent to uninstalling Containerd" {
            Mock Uninstall-ContainerToolConsent -ModuleName 'ContainerdTools' -MockWith { return $false }

            $ENV:PESTER = $true
            { Uninstall-Containerd -Path 'TestDrive:\Program Files\Containerd' -Confirm:$false -Force:$false } | Should -Throw "Containerd uninstallation cancelled."
        }

        It "Should successfully call uninstall Containerd helper function" {
            Uninstall-ContainerdHelper -Path 'TestDrive:\Program Files\Containerd'

            Should -Invoke Stop-ContainerdService -Times 1 -Scope It -ModuleName "ContainerdTools"
            Should -Invoke Unregister-Containerd -Times 1 -Scope It -ModuleName "ContainerdTools"
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "ContainerdTools" `
                -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\containerd' }
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "ContainerdTools" `
                -ParameterFilter { $Path -eq 'TestDrive:\Program Files\Containerd' }
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "ContainerdTools" `
                -ParameterFilter { $Path -eq "$ENV:ProgramData\Containerd" }
            Should -Invoke Remove-FeatureFromPath -Times 1 -Scope It -ModuleName "ContainerdTools" `
                -ParameterFilter { $Feature -eq "containerd" }
        }

        It "Should do nothing if containerd is not installed at specified path" {
            Mock Test-EmptyDirectory -ModuleName 'ContainerdTools' -MockWith { return $true }

            Uninstall-ContainerdHelper -Path 'TestDrive:\Program Files\Containerd'

            Should -Invoke Stop-ContainerdService -Times 0 -Scope It -ModuleName "ContainerdTools"
            Should -Invoke Unregister-Containerd -Times 0 -Scope It -ModuleName "ContainerdTools"
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "ContainerdTools"
            Should -Invoke Remove-FeatureFromPath -Times 0 -Scope It -ModuleName "ContainerdTools"

            $Error[0].Exception.Message | Should -BeExactly 'Containerd does not exist at TestDrive:\Program Files\Containerd or the directory is empty.'
        }

        It "Should throw an error if containerd service stop or unregister was unsuccessful" {
            Mock Stop-ContainerdService -ModuleName 'ContainerdTools' -MockWith { Throw 'Error' }

            { Uninstall-ContainerdHelper -Path 'TestDrive:\Program Files\Containerd' } | Should -Throw "Could not stop or unregister containerd service.*"
            Should -Invoke Unregister-Containerd -Times 0 -Scope It -ModuleName "ContainerdTools"
            Should -Invoke Remove-Item -Times 0 -Scope It -ModuleName "ContainerdTools"
            Should -Invoke Remove-FeatureFromPath -Times 0 -Scope It -ModuleName "ContainerdTools"
        }
    }
}