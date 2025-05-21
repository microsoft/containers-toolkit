###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

using module ..\containers-toolkit\Private\Logger.psm1

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

        # Mock functions
        Mock New-EventLog -ModuleName 'Logger'
        Mock Write-EventLog -ModuleName 'Logger'
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
            # Mock get version
            $mockConfigStdOut = New-MockObject -Type 'System.IO.StreamReader' -Methods @{ ReadToEnd = { return "tool version v1.0.1" } }
            $mockConfigProcess = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{
                ExitCode       = 0
                StandardOutput = $mockConfigStdOut
            }
            Mock Invoke-ExecutableCommand -ModuleName "AllToolsUtilities" `
                -ParameterFilter { $Arguments -eq "--version" } `
                -MockWith { return $mockConfigProcess }
        }

        It "Should get containerd version" {
            $executablePath = "TestDrive:\Program Files\Containerd\bin\containerd.exe"
            Mock Get-Command -ModuleName 'AllToolsUtilities' -MockWith { @{ Name = 'containerd.exe'; Source = $executablePath } }
            Mock Get-Service -ModuleName 'AllToolsUtilities'

            $containerdVersion = Show-ContainerTools -ToolName 'containerd'

            # Check the output
            $expectedOutput = [PSCustomObject]@{
                Tool         = 'containerd'
                Path         = $executablePath
                Installed    = $true
                Version      = 'v1.0.1'
                Daemon       = 'containerd'
                DaemonStatus = 'Unregistered'
            }
            # $containerdVersion | Should -Be $expectedOutput
            # HACK: Should -Be does not work with PSCustomObject in PSv5.
            # However PSv6 has support for this. To be investigated further.
            foreach ($key in $expectedOutput.Keys) {
                $expectedValue = $expectedOutput[$key]
                $actualValue = $containerdVersion.$key
                $actualValue | Should -Be $expectedValue
            }

            # Check the invocation
            Should -Invoke Get-Command -ModuleName 'AllToolsUtilities' `
                -Times 1 -Exactly -Scope It  -ParameterFilter { $Name -eq 'containerd.exe' }
        }

        It "Should get buildkit version" {
            $executablePath = "TestDrive:\Program Files\Buildkit\bin\buildkitd.exe"
            $buildctlPath = "TestDrive:\Program Files\Buildkit\bin\buildctl.exe"

            Mock Get-Service -ModuleName 'AllToolsUtilities' -MockWith { @{ Status = "Running" } }
            Mock Get-Command -ModuleName 'AllToolsUtilities' -MockWith { @(
                    @{ Name = 'buildkitd.exe'; Source = $executablePath }
                    @{ Name = 'buildctl.exe'; Source = $buildctlPath }
                ) }

            $buildkitVersion = Show-ContainerTools -ToolName 'buildkit'

            # Check the output
            $expectedOutput = [PSCustomObject]@{
                Tool         = 'buildkit'
                Path         = $executablePath
                Installed    = $true
                Version      = 'v1.0.1'
                Daemon       = 'buildkitd'
                DaemonStatus = 'Running'
                BuildctlPath = $buildctlPath
            }
            foreach ($key in $expectedOutput.Keys) {
                $expectedValue = $expectedOutput[$key]
                $actualValue = $buildkitVersion.$key
                $actualValue | Should -Be $expectedValue
            }

            # Check the invocation
            Should -Invoke Get-Command -ModuleName 'AllToolsUtilities' `
                -Times 1 -Exactly -Scope It  -ParameterFilter { $Name -eq "build*.exe" }
        }

        It "Should return basic info if the tool is not installed" {
            Mock Get-Command -ModuleName 'AllToolsUtilities'

            $toolInfo = Show-ContainerTools

            # Check the output
            $expectedOutput = @(
                [PSCustomObject]@{ Tool = 'containerd'; Installed = $false; Daemon = 'containerd'; DaemonStatus = 'Unregistered' }
                [PSCustomObject]@{ Tool = 'buildkit'; Installed = $false; Daemon = 'buildkitd'; DaemonStatus = 'Unregistered' }
                [PSCustomObject]@{ Tool = 'nerdctl'; Installed = $false }
            )
            $expectedOutput | ForEach-Object {
                $tool = $_.Tool
                $actualOutput = $toolInfo | Where-Object { $_.Tool -eq $tool }
                foreach ($key in $_.Keys) {
                    $expectedValue = $_[$key]
                    $actualValue = $actualOutput.$key
                    $actualValue | Should -Be $expectedValue
                }
            }
        }

        It "Should return latest version if Latest flag is specified" {
            Mock Get-Command -ModuleName 'AllToolsUtilities'

            $toolInfo = Show-ContainerTools -Latest

            # Check the output
            $expectedOutput = @(
                [PSCustomObject]@{ Tool = 'containerd'; Installed = $false; Daemon = 'buildkitd'; DaemonStatus = 'Unregistered'; LatestVersion = 'v1.0.1' }
                [PSCustomObject]@{ Tool = 'buildkit'; Installed = $false; Daemon = 'buildkitd'; DaemonStatus = 'Unregistered'; LatestVersion = 'v1.0.1' }
                [PSCustomObject]@{ Tool = 'nerdctl'; Installed = $false; LatestVersion = 'v1.0.1' }
            )
            $expectedOutput | ForEach-Object {
                $tool = $_.Tool
                $actualOutput = $toolInfo | Where-Object { $_.Tool -eq $tool }
                foreach ($key in $_.Keys) {
                    $expectedValue = $_[$key]
                    $actualValue = $actualOutput.$key
                    $actualValue | Should -Be $expectedValue
                }
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
