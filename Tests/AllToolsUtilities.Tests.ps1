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
        Import-Module -Name "$ModuleParentPath\Public\AllToolsUtilities.psm1" -Force
    }

    AfterAll {
        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\AllToolsUtilities.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\ContainerdTools.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\BuildkitTools.psm1" -Force -ErrorAction Ignore
        Remove-Module -Name "$ModuleParentPath\Public\NerdctlTools.psm1" -Force -ErrorAction Ignore
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
            Mock Get-ContainerdLatestVersion -ModuleName 'AllToolsUtilities' -MockWith { return '4.9.0' }
            Mock Get-BuildkitLatestVersion -ModuleName 'AllToolsUtilities' -MockWith { return '8.9.7' }
            Mock Get-NerdctlLatestVersion -ModuleName 'AllToolsUtilities' -MockWith { return '1.5.3' }
            Mock Get-InstallationFiles -ModuleName 'AllToolsUtilities'
            Mock Uninstall-ContainerTool -ModuleName 'AllToolsUtilities'
            Mock Install-RequiredFeature -ModuleName 'AllToolsUtilities'
            Mock Install-ContainerToolConsent -ModuleName 'AllToolsUtilities' -MockWith { return $true }
            Mock Install-ContainerTools -ModuleName 'AllToolsUtilities'
            Mock Test-EmptyDirectory  -ModuleName 'BuildkitTools' -MockWith { return $true }
        }

        It 'Should not process on implicit request for validation (WhatIfPreference)' {
            {
                $WhatIfPreference = $true
                Install-ContainerTools
            }
            Should -Invoke -CommandName Install-ContainerTools -ModuleName 'AllToolsUtilities' -Exactly -Times 0 -Scope It
        }

        It 'Should not process on explicit request for validation (-WhatIf)' {
            { Install-ContainerTools -WhatIf }
            Should -Invoke -CommandName Install-ContainerTools -ModuleName 'AllToolsUtilities' -Exactly -Times 0 -Scope It
        }

        It "Should use defaults" {
            Mock Test-EmptyDirectory -ModuleName 'AllToolsUtilities' -MockWith { return $false }

            Install-ContainerTools -Confirm:$false

            $containerdTarFile = "containerd-4.9.0-windows-amd64.tar.gz"
            $BuildKitTarFile = "buildkit-v8.9.7.windows-amd64.tar.gz"
            $nerdctlTarFile = "nerdctl-1.5.3-windows-amd64.tar.gz"
            $MockToolParams = @(
                [PSCustomObject]@{
                    Feature      = "Containerd"
                    Uri          = "https://github.com/containerd/containerd/releases/download/v4.9.0/$containerdTarFile"
                    Version      = '4.9.0'
                    DownloadPath = "$HOME\Downloads\$($containerdTarFile)"
                    InstallPath  = "$Env:ProgramFiles\Containerd"
                    EnvPath      = "$Env:ProgramFiles\Containerd\bin"
                }
                [PSCustomObject]@{
                    Feature      = "BuildKit"
                    Uri          = "https://github.com/moby/buildkit/releases/download/v8.9.7/$BuildKitTarFile"
                    Version      = '8.9.7'
                    DownloadPath = "$HOME\Downloads\$($BuildKitTarFile)"
                    InstallPath  = "$Env:ProgramFiles\BuildKit"
                    EnvPath      = "$Env:ProgramFiles\BuildKit\bin"
                }
                [PSCustomObject]@{
                    Feature      = "nerdctl"
                    Uri          = "https://github.com/containerd/nerdctl/releases/download/v1.5.3/$nerdctlTarFile"
                    Version      = '1.5.3'
                    DownloadPath = "$HOME\Downloads\$($nerdctlTarFile)"
                    InstallPath  = "$Env:ProgramFiles\nerdctl"
                    EnvPath      = "$Env:ProgramFiles\nerdctl"
                }
            )

            Should -Invoke Get-InstallationFiles -ModuleName 'AllToolsUtilities' -Times 1 -Exactly -Scope It `
                -ParameterFilter { @{$Files = $MockToolParams } }

            foreach ($mockParam in $MockToolParams) {
                $MockInstallParams = @{
                    Feature      = $mockParam.Feature
                    InstallPath  = $mockParam.InstallPath
                    DownloadPath = $mockParam.DownloadPath
                    EnvPath      = $mockParam.EnvPath
                }

                Should -Invoke "Get-$($mockParam.Feature)LatestVersion" -ModuleName 'AllToolsUtilities' -Times 1 -Exactly -Scope It

                # "Should uninstall tool if it is already installed"
                Should -Invoke Uninstall-ContainerTool -ModuleName 'AllToolsUtilities' -Times 1 -Exactly -Scope It `
                    -ParameterFilter { $Tool -eq $mockParam.Feature -and $Path -eq $mockParam.InstallPath -and $force -eq $false }

                Should -Invoke Install-RequiredFeature -ModuleName 'AllToolsUtilities' -ParameterFilter { $MockInstallParams -and $cleanup -eq $false }
            }
        }

        It "Should use user-specified values" {
            Install-ContainerTools `
                -ContainerDVersion '7.8.9' `
                -BuildKitVersion '4.5.6' `
                -NerdCTLVersion '3.2.1' `
                -InstallPath 'TestDrive:\Install Directory' `
                -DownloadPath 'TestDrive:\Download Directory' `
                -Force -Confirm:$false

            $containerdTarFile = "containerd-7.8.9-windows-amd64.tar.gz"
            $BuildKitTarFile = "buildkit-v4.5.6.windows-amd64.tar.gz"
            $nerdctlTarFile = "nerdctl-3.2.1-windows-amd64.tar.gz"
            $MockToolParams = @(
                [PSCustomObject]@{
                    Feature      = "Containerd"
                    Uri          = "https://github.com/containerd/containerd/releases/download/v7.8.9/$containerdTarFile"
                    Version      = '7.8.9'
                    DownloadPath = "$HOME\Downloads\$($containerdTarFile)"
                    InstallPath  = "TestDrive:\Install Directory\Containerd"
                    EnvPath      = "TestDrive:\Install Directory\Containerd\bin"
                }
                [PSCustomObject]@{
                    Feature      = "BuildKit"
                    Uri          = "https://github.com/moby/buildkit/releases/download/v4.5.6/$BuildKitTarFile"
                    Version      = '4.5.6'
                    DownloadPath = "$HOME\Downloads\$($BuildKitTarFile)"
                    InstallPath  = "TestDrive:\Install Directory\BuildKit"
                    EnvPath      = "TestDrive:\Install Directory\BuildKit\bin"
                }
                [PSCustomObject]@{
                    Feature      = "nerdctl"
                    Uri          = "https://github.com/containerd/nerdctl/releases/download/v3.2.1/$nerdctlTarFile"
                    Version      = '3.2.1'
                    DownloadPath = "$HOME\Downloads\$($nerdctlTarFile)"
                    InstallPath  = "TestDrive:\Install Directory\nerdctl"
                    EnvPath      = "TestDrive:\Install Directory\nerdctl"
                }
            )

            Should -Invoke Get-InstallationFiles -ModuleName 'AllToolsUtilities' -Times 1 -Exactly -Scope It `
                -ParameterFilter { @{$Files = $MockToolParams } }

            foreach ($mockParam in $MockToolParams) {
                $MockInstallParams = @{
                    Feature      = $mockParam.Feature
                    InstallPath  = $mockParam.InstallPath
                    DownloadPath = $mockParam.DownloadPath
                    EnvPath      = $mockParam.EnvPath
                }

                Should -Invoke "Get-$($mockParam.Feature)LatestVersion" -ModuleName 'AllToolsUtilities' -Times 0 -Scope It
                Should -Invoke Uninstall-ContainerTool -ModuleName 'AllToolsUtilities' -Times 0 -Exactly -Scope It
                Should -Invoke Install-RequiredFeature -ModuleName 'AllToolsUtilities' -ParameterFilter { $MockInstallParams }
            }
        }

        It "Should continue installation of other tools on failure" {
            Mock Test-EmptyDirectory -ModuleName 'AllToolsUtilities' -MockWith { return $false }
            Mock Uninstall-ContainerTool -ModuleName 'AllToolsUtilities' -ParameterFilter { $Tool -eq 'Containerd' } -MockWith { Throw 'Error message' }

            Install-ContainerTools -Force -Confirm:$false

            Should -Invoke Install-RequiredFeature -ModuleName 'AllToolsUtilities' -Times 0 -Exactly -Scope It -ParameterFilter { $Feature -eq 'Containerd' }

            foreach ($tool in @('buildkit', 'nerdctl')) {
                Should -Invoke Install-RequiredFeature -ModuleName 'AllToolsUtilities' -Times 1 -Exactly -Scope It -ParameterFilter { $Feature -eq $tool }
            }
        }
    }
}