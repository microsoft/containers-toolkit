###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


Describe "CommonToolUtilities.psm1" {
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'Containers-Toolkit'
        Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force
        Import-Module -Name "$ModuleParentPath\Private\UpdateEnvironmentPath.psm1" -Force

        $DownloadPath = "TestDrive:\Download"
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null

        $ProgramFiles = "TestDrive:\Program Files"
        New-Item -Path $ProgramFiles -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        Get-ChildItem "TestDrive:\" | Remove-Item -Recurse -Force

        Remove-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force -ErrorAction Ignore
    }

    Context "Get-LatestToolVersion" -Tag "Get-LatestToolVersion" {
        It "Should return the latest version for a tool" {
            $sampleOutput = @{
                StatusCode        = 200
                StatusDescription = 'OK'
                Content           = (Get-Content $PSScriptRoot\TestData\latestVersion.json)
                Headers           = @()
                Images            = $null
                InputFields       = $null
                Links             = $null
                RawContentLength  = 49618
                RelationLink      = $null
            }
            Mock Invoke-WebRequest { $sampleOutput } -ModuleName "CommonToolUtilities"

            $result = Get-LatestToolVersion -Repository "test/tool"

            $expectedUri = "https://api.github.com/repos/test/tool/releases/latest"
            Should -Invoke Invoke-WebRequest -ParameterFilter { $Uri -eq $expectedUri } -Exactly 1 -Scope It -ModuleName "CommonToolUtilities"
            $result | Should -Be '0.12.3'
        }

        It "Should throw an error if API call fails" {
            $errorMessage = "Response status code does not indicate success: 404 (Not Found)."
            Mock Invoke-WebRequest -MockWith { Throw $errorMessage } -ModuleName "CommonToolUtilities"
            { Get-LatestToolVersion -Repository "test/tool" } | Should -Throw "Could not get tool latest version. $errorMessage"
        }
    }

    Context "Test-EmptyDirectory" -Tag "Test-EmptyDirectory" {
        BeforeAll {
            $testFolder = Join-Path $TestDrive 'TestFolder'
        }

        AfterEach {
            Get-ChildItem $TestDrive | Remove-Item -Recurse -Force
        }

        It "Should return true if directory does not exist" {
            Test-EmptyDirectory -Path $testFolder | Should -Be $true

        }

        It "Should return true if directory is empty" {
            New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
            New-Item -Path "$testFolder\bin" -ItemType Directory -Force | Out-Null

            Test-EmptyDirectory "$testFolder\bin" | Should -Be $true
        }

        It "Should return false if directory is not empty" {
            New-Item -Path $testFolder -ItemType Directory | Out-Null
            New-Item -Path "$testFolder\bin" -ItemType Directory | Out-Null
            New-Item -Path "$testFolder\testfile.txt" -ItemType "File" -Force | Out-Null

            Test-EmptyDirectory $testFolder | Should -Be $false
        }
    }

    Context "Get-InstallationFiles" -Tag "Get-InstallationFiles" {
        BeforeAll {
            # Functions in the ThreadJob module
            function Start-ThreadJob { }
            function Wait-Job { return @( $sampleJob  ) }
            function Receive-Job { }
            function Remove-Job { }

            Mock Get-Module -ParameterFilter { $Name -eq 'ThreadJob' } { }
            Mock Import-Module -ParameterFilter { $Name -eq 'ThreadJob' } { }
            Mock Invoke-WebRequest { } -ModuleName "CommonToolUtilities"

            $sampleJob = New-MockObject -Type 'ThreadJob.ThreadJob' -Properties @{ JobStateInfo = 'Completed' }
            Mock Start-ThreadJob -ModuleName "CommonToolUtilities" -MockWith { return $sampleJob }
            Mock Wait-Job -ModuleName "CommonToolUtilities"
            Mock Receive-Job -ModuleName "CommonToolUtilities"
            Mock Remove-Job -ModuleName "CommonToolUtilities"
        }

        It "Should successfully download single file" {
            $params = @{
                Feature      = "Containerd"
                Uri          = "https://github.com/v1.0.0/downloadedfile.tar.gz"
                Version      = '1.0.0'
                DownloadPath = "$DownloadPath\downloadedfile.tar.gz"
            }
            $files = @($params)
            Get-InstallationFiles -Files $files

            Should -Invoke Invoke-WebRequest -Exactly 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter { $Uri -eq $params.Uri -and $Outfile -eq $params.DownloadPath }
            Should -Invoke Invoke-WebRequest -Exactly 1 -Scope It -ModuleName "CommonToolUtilities"
            Should -Invoke Start-ThreadJob  -Exactly 0 -Scope It -ModuleName "CommonToolUtilities"
        }

        It "Should successfully download muliple files asynchronously" {

            $files = @(
                @{
                    Feature      = "Containerd"
                    Uri          = "https://github.com/v1.0.0/Containerdfile.tar.gz"
                    Version      = '1.0.0'
                    DownloadPath = "$DownloadPath\downloadedfile.tar.gz"
                }
                @{
                    Feature      = "Buildkit"
                    Uri          = "https://github.com/v1.0.0/Buildkitfile.tar.gz"
                    Version      = '1.0.0'
                    DownloadPath = "$DownloadPath\downloadedfile.tar.gz"
                }
            )
            # $containerdParams = $files[0]
            # $buildkitParams = $files[1]
            Get-InstallationFiles -Files $files

            # Should -Invoke Invoke-WebRequest -Exactly 1 -Scope It -ModuleName "CommonToolUtilities" `
            #     -ParameterFilter { $Uri -eq $containerdParams.Uri -and $Outfile -eq $containerdParams.DownloadPath }
            # Should -Invoke Invoke-WebRequest -Exactly 1 -Scope It -ModuleName "CommonToolUtilities" `
            #     -ParameterFilter { $Uri -eq $buildkitParams.Uri -and $Outfile -eq $buildkitParams.DownloadPath }
            # Should -Invoke Invoke-WebRequest -Exactly 2 -Scope It -ModuleName "CommonToolUtilities"
            Should -Invoke Start-ThreadJob -Exactly 2 -Scope It -ModuleName "CommonToolUtilities"
            Should -Invoke Receive-Job -Exactly 2 -Scope It -ModuleName "CommonToolUtilities"
        }

        It "Should throw an error if download fails" {
            $params = @{
                Feature      = "Containerd"
                Uri          = "https://github.com/v1.0.0/downloadedfile.tar.gz"
                Version      = '1.0.0'
                DownloadPath = "$DownloadPath\downloadedfile.tar.gz"
            }
            $files = @($params)

            $errorMessage = "Response status code does not indicate success: 404 (Not Found)."
            Mock Invoke-WebRequest { Throw $errorMessage } -ModuleName "CommonToolUtilities"
            { Get-InstallationFiles -Files $files } | Should -Throw "Containerd downlooad failed: https://github.com/v1.0.0/downloadedfile.tar.gz.`n$errorMessage"
        }
    }

    Context "Get-DefaultInstallPath" -Tag "Get-DefaultInstallPath" {
        It "Should return the install path for buildkit if buildkit binaries are in the environment path" {
            Mock Get-Command -ModuleName "CommonToolUtilities" -MockWith { return @(
                    [PSCustomObject]@{
                        Name        = 'buildctl.exe'
                        CommandType = 'Application'
                        Definition  = 'C:\ProgramData\Buildkit\bin\buildctl.exe'
                        Extension   = '.exe'
                        Source      = 'C:\ProgramData\Buildkit\bin\buildctl.exe'
                    },
                    [PSCustomObject]@{
                        Name        = 'buildkitd.exe'
                        CommandType = 'Application'
                        Definition  = 'C:\ProgramData\Buildkit\bin\buildkitd.exe'
                        Extension   = '.exe'
                        Source      = 'C:\ProgramData\Buildkit\bin\buildkitd.exe'
                    }) }
            Get-DefaultInstallPath -Tool buildkit | Should -Be 'C:\ProgramData\Buildkit'
        }

        It "Should return the default path for a tool binaries are not in the environment path" {
            Mock Get-Command { } -ModuleName "CommonToolUtilities"
            Get-DefaultInstallPath -Tool containerd | Should -Be "$Env:ProgramFiles\Containerd"
        }
    }

    Context "Install-RequiredFeature" -Tag "Install-RequiredFeature" {
        BeforeAll {
            $obj = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{ ExitCode = 0 }
            Mock Invoke-ExecutableCommand -ModuleName "CommonToolUtilities" -MockWith { return $obj }
            Mock Add-FeatureToPath -ModuleName "CommonToolUtilities"
            Mock New-Item -ModuleName "CommonToolUtilities"
            Mock Remove-Item -ModuleName "CommonToolUtilities"
        }

        It "Should successfully install tool" {
            $params = @{
                Feature      = "containerd"
                InstallPath  = "$ProgramFiles\Containerd"
                DownloadPath = "$DownloadPath\containerd-binaries.tar.gz"
                EnvPath      = "$ProgramFiles\Containerd\bin"
                cleanup      = $true
            }

            Install-RequiredFeature @params

            #  Check that the dir is created if it does not exist
            Should -Invoke New-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter { ($Path -eq $params.InstallPath) }

            # Test that the file is untar-ed
            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter { ($Executable -eq 'tar.exe') -and ($Arguments -eq "-xf `"$($params.DownloadPath)`" -C `"$($params.InstallPath)`"") }

            # Test that method to add feature to path is called
            Should -Invoke Add-FeatureToPath -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter { ($Feature -eq $params.Feature) -and ($Path -eq $params.EnvPath) }

            # Check that clean up is done on completion
            Should -Invoke Remove-Item  -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter { $Path -eq $params.DownloadPath }
        }

        It "should not remove items if cleanup is false" {
            $params = @{
                Feature      = "containerd"
                InstallPath  = "$ProgramFiles\Containerd"
                DownloadPath = "$DownloadPath\containerd-binaries.tar.gz"
                EnvPath      = "$ProgramFiles\Containerd\bin"
                cleanup      = $false
            }
            Install-RequiredFeature @params
            Should -Invoke Remove-Item -ModuleName "CommonToolUtilities" -Times 0 -Scope It
        }

        It "should throw an error if tar command fails" {
            $obj = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{
                ExitCode      = 1
                StandardError = New-MockObject -Type 'System.IO.StreamReader' -Methods @{
                    ReadToEnd = { return "Error message" }
                }
            }
            Mock Invoke-ExecutableCommand -ModuleName "CommonToolUtilities" -MockWith { return $obj }
            $params = @{
                Feature      = "containerd"
                InstallPath  = "$ProgramFiles\Containerd"
                DownloadPath = "$DownloadPath\containerd-binaries.tar.gz"
                EnvPath      = "$ProgramFiles\Containerd\bin"
                cleanup      = $false
            }

            { Install-RequiredFeature @params } | Should -Throw "Could not untar file $($params.DownloadPath) at $($params.InstallPath). Error message"
        }
    }

    Context "Uninstall-ContainerToolConsent" -Tag "Uninstall-ContainerToolConsent" {
        It "Should return true if user consents to uninstall" {
            $yesValue = [ActionConsent]::Yes.value__
            Mock Get-Host -ModuleName "CommonToolUtilities" -MockWith { return [UITest]::new($yesValue) }
            $result = Uninstall-ContainerToolConsent -Tool 'Tool' -Path "TestDrive:\Tool"
            $result | Should -BeTrue
        }

        It "Should return false if user does not consent to uninstall" {
            $noValue = [ActionConsent]::No.value__
            Mock Get-Host -ModuleName "CommonToolUtilities" -MockWith { return [UITest]::new($noValue) }
            $result = Uninstall-ContainerToolConsent -Tool 'Tool' -Path "TestDrive:\Tool"
            $result | Should -BeFalse
        }
    }

    Context "Add-FeatureToPath" -Tag "Add-FeatureToPath" {
        It "Should call Update-EnvironmentPath to add feature to path" {
            # Mocks
            $testPathToAdd = "TestDrive:\TestPath"
            Mock Update-EnvironmentPath -ModuleName "CommonToolUtilities"

            Add-FeatureToPath -Feature Tool -Path $testPathToAdd

            # Assert
            @("User", "System") | ForEach-Object {
                Should -Invoke Update-EnvironmentPath -ModuleName 'CommonToolUtilities' `
                    -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Tool -eq "Tool" -and
                    $Path -eq $testPathToAdd -and
                    $Action -eq 'Add' -and
                    $PathType -eq $_
                }
            }
        }
    }

    Context "Remove-FeatureFromPath" -Tag "Remove-FeatureFromPath" {
        It "Should call Update-EnvironmentPath to remove feature to path" {
            # Mocks
            Mock Update-EnvironmentPath -ModuleName "CommonToolUtilities"

            Remove-FeatureFromPath -Feature "Tool"

            # Assert
            @("User", "System") | ForEach-Object {
                Should -Invoke Update-EnvironmentPath -ModuleName 'CommonToolUtilities' `
                    -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Tool -eq "Tool" -and
                    $Path -eq $null -and
                    $Action -eq 'Remove' -and
                    $PathType -eq $_
                }
            }
        }
    }

    Context "Invoke-ServiceAction" -Tag "Invoke-ServiceAction" {
        BeforeAll {
            function Test-ServiceRegistered { }
            Mock Test-ServiceRegistered -ModuleName "CommonToolUtilities" -MockWith { return $true }

            # $MockService = New-MockObject -Type System.ServiceProcess.ServiceController -Methods @{ WaitForStatus = { } }
            # Mock Get-Service -ModuleName "CommonToolUtilities" -MockWith { return $MockService }
            Mock Get-Service -ModuleName "CommonToolUtilities" -MockWith { return [MockService]::new('MockService') }
        }

        It "Should show a warning if service does not exist" {
            Mock Get-Service -MockWith { } -ModuleName "CommonToolUtilities"
            Mock Test-ServiceRegistered -ModuleName "CommonToolUtilities" -MockWith { return $false }

            { Invoke-ServiceAction -Action 'Start' -Service 'MockService' } | Should -Throw "MockService service does not exist as an installed service."
        }

        It "Should successfully start service" {
            Mock Start-Service -ModuleName "CommonToolUtilities"

            Invoke-ServiceAction -Action 'Start' -Service 'MockService'

            Should -Invoke Get-Service -ModuleName "CommonToolUtilities" -ParameterFilter { $Name -like "MockService" }
            Should -Invoke Start-Service -ModuleName "CommonToolUtilities" -ParameterFilter { $Name -like "MockService" }
        }

        It "Should successfully stop service" {
            Mock Stop-Service -ModuleName "CommonToolUtilities"

            Invoke-ServiceAction -Action 'Stop' -Service 'MockService'
            Should -Invoke Stop-Service -ModuleName "CommonToolUtilities" -ParameterFilter { $Name -like "MockService" }
        }

        It "Should throw an error if invoked action fails" {
            Mock Start-Service -ModuleName "CommonToolUtilities" -MockWith { Throw 'Error Message.' }

            { Invoke-ServiceAction -Action 'Start' -Service 'MockService' } | Should -Throw "Couldn't start MockService service. Error Message."
        }

        It "Should throw an error if specified action is not implemeted" {
            { Invoke-ServiceAction -Action 'Random action' -Service 'MockService' } | Should -Throw "Not implemented"
        }
    }
}