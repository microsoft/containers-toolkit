###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


using module "..\containers-toolkit\Private\CommonToolUtilities.psm1"

$Script:SampleSha256Sum = @'
6b8ff12339733a6SSaMpLeSHAe2ff9f8d333c9e898  nerdctl-2.0.0-linux-amd64.tar.gz
736a3c6e092daab5SaMpLeSHAd177018ff706mb2ad  nerdctl-2.0.0-linux-arm-v7.tar.gz
0286780561d8eb915922b9SaMpLeSHA45abdfeef3e  ./release/nerdctl-2.0.0-linux-arm64.tar.gz
__CHECKSUM__  nerdctl-2.0.0-windows-amd64.tar.gz
'@

$Script:SbomJson = @'
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://spdx.dev/Document",
  "subject": [
    {
      "name": "buildkit-v1.0.0.windows-amd64.tar.gz",
      "digest": {
        "sha256": "__CHECKSUM__"
      }
    }
  ]
}
'@

$Script:InvalidFileNameJson = @'
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://spdx.dev/Document",
  "subject": [
    {
      "name": "sample-tool.tar.gz",
      "digest": {
        "sha99": "e433c3d3484ad5c13SAMPLESHA310ad5f90f7060"
      }
    }
  ]
}
'@


$Script:OtherSbomFormatJson = @'
{
  "_type": "https://some-other-format-other-than-in-toto.io/Statement/v0.1",
  "predicateType": "https://spdx.dev/Document",
  "subject": [
    {
      "name": "buildkit-v1.0.0.windows-amd64.tar.gz",
      "digest": {
          "sha256": "SampleHash"
        }
    }
  ]
}
'@

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
        Remove-Module -Name "$ModuleParentPath\Private\UpdateEnvironmentPath.psm1" -Force -ErrorAction Ignore
    }

    Context "Get-LatestToolVersion" -Tag "Get-LatestToolVersion" {
        BeforeEach {
            $expectedUri = "https://api.github.com/repos/containerd/containerd/releases/latest"
        }

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

            $result = Get-LatestToolVersion -Tool "containerd"

            Should -Invoke Invoke-WebRequest -ParameterFilter { $Uri -eq $expectedUri } -Exactly 1 -Scope It -ModuleName "CommonToolUtilities"
            $result | Should -Be '0.12.3'
        }

        It "Should throw an error if invalid tool name is provided" {
            { Get-LatestToolVersion -Tool "invalid-tool" } | Should -Throw "Couldn't get latest invalid-tool version. Invalid tool name: 'invalid-tool'."
        }

        It "Should throw an error if API call fails" {
            $errorMessage = "Response status code does not indicate success: 404 (Not Found)."
            Mock Invoke-WebRequest -MockWith { Throw $errorMessage } -ModuleName "CommonToolUtilities"
            { Get-LatestToolVersion -Tool "containerd" } | Should -Throw "Couldn't get containerd latest version from $expectedUri. $errorMessage"
        }
    }

    Context "Test-EmptyDirectory" -Tag "Test-EmptyDirectory" {
        BeforeAll {
            $Script:testFolder = Join-Path $TestDrive 'TestFolder'
        }

        AfterEach {
            Get-ChildItem $TestDrive | Remove-Item -Recurse -Force
        }

        It "Should return true if directory does not exist" {
            Test-EmptyDirectory -Path $Script:testFolder | Should -Be $true

        }

        It "Should return true if directory is empty" {
            New-Item -Path $Script:testFolder -ItemType Directory -Force | Out-Null
            New-Item -Path "$Script:testFolder\bin" -ItemType Directory -Force | Out-Null

            Test-EmptyDirectory "$Script:testFolder\bin" | Should -Be $true
        }

        It "Should return false if directory is not empty" {
            New-Item -Path $Script:testFolder -ItemType Directory | Out-Null
            New-Item -Path "$Script:testFolder\bin" -ItemType Directory | Out-Null
            New-Item -Path "$Script:testFolder\testfile.txt" -ItemType "File" -Force | Out-Null

            Test-EmptyDirectory $Script:testFolder | Should -Be $false
        }
    }

    Context "Get-InstallationFile" -Tag "Get-InstallationFile" {
        BeforeEach {
            Mock Invoke-WebRequest -ModuleName "CommonToolUtilities" { }
            Mock Invoke-RestMethod -ModuleName "CommonToolUtilities" {
                return (Get-Content -Path "$PSScriptRoot\TestData\release-assets.json" -Raw | ConvertFrom-Json -Depth 3 )
            }
            Mock Test-Checksum -ModuleName "CommonToolUtilities" -MockWith { return $true }

            $Script:TestFileName = "nerdctl-2.0.0-rc.1-windows-amd64.tar.gz"
            $Script:MockDownloadPath = "TestDrive:\Download\$testFileName"
            $Script:MockCheckSumFile = "TestDrive:\Download\SHA256SUMS"
            $Script:MockURL = "https://github.com/containerd/nerdctl/releases/download/v2.0.0-rc.1/$testFileName"
            $Script:MockFiles = @(
                @{
                    Feature        = "Containerd"
                    Repo           = "containerd/nerdctl"
                    Version        = 'latest'
                    OSArchitecture = 'amd64'
                    DownloadPath   = "TestDrive:\Download"
                }
            )

            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true } -ParameterFilter { $Path -eq $Script:MockDownloadPath }
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true } -ParameterFilter { $Path -eq $Script:MockCheckSumFile }
        }

        It "Should successfully download latest release assets" {
            $testChecksumURI = "https://github.com/containerd/nerdctl/releases/download/v2.0.0-rc.1/SHA256SUMS"
            $testChecksumFile = "TestDrive:\Download\SHA256SUMS"

            # Call method
            $result = Get-InstallationFile -FileParameters $Script:MockFiles

            # Assert
            $result | Should -Be $Script:MockDownloadPath
            Should -Invoke Invoke-RestMethod -Exactly 1 -Scope It -ModuleName "CommonToolUtilities"
            Should -Invoke Invoke-RestMethod -Exactly 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Uri -eq "https://api.github.com/repos/containerd/nerdctl/releases/latest" }
            Should -Invoke Invoke-WebRequest -Exactly 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Uri -eq $Script:MockURL -and $Outfile -eq $Script:MockDownloadPath }
            Should -Invoke Invoke-WebRequest -Exactly 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Uri -eq $testChecksumURI -and $Outfile -eq $testChecksumFile }
        }

        It "Should successfully download release assets for specified version" {
            Mock Invoke-RestMethod -ModuleName "CommonToolUtilities" {
                return (Get-Content -Path "$PSScriptRoot\TestData\release-tags.json" -Raw | ConvertFrom-Json -Depth 10 )
            } -ParameterFilter { $Uri -eq "https://api.github.com/repos/containerd/nerdctl/tags" }

            $files = $Script:MockFiles
            $files[0].Version = 'v2.0.0-rc.1'
            $files[0].FileFilterRegEx = "(?:.tar.gz|SHA256SUMS)$"

            # Call method
            $result = Get-InstallationFile -FileParameters $files

            # Assert
            $result | Should -Be "$Script:MockDownloadPath"
            # 1. tags, 2. releases for the specified version
            Should -Invoke Invoke-RestMethod -Exactly 2 -Scope It -ModuleName "CommonToolUtilities"
            Should -Invoke Invoke-RestMethod -Exactly 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Uri -eq "https://api.github.com/repos/containerd/nerdctl/tags" }
            Should -Invoke Invoke-RestMethod -Exactly 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Uri -eq "https://api.github.com/repos/containerd/nerdctl/releases/tags/v2.0.0-rc.1" }
            Should -Invoke Invoke-WebRequest -Exactly 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Uri -eq $Script:MockURL -and $Outfile -eq $Script:MockDownloadPath }
        }

        It "Should throw an error if no release exists for the specified version" {
            $files = @(
                @{
                    Feature      = "nerdctl"
                    Repo         = "containerd/nerdctl"
                    Version      = 'v8.i.0'
                    DownloadPath = "TestDrive:\Download"
                }
            )

            # Call method
            { Get-InstallationFile -FileParameters $files } | Should -Throw "Couldn't find release tags for the provided version: 'v8.i.0'"
        }

        It "Should throw an error if no release exists for the specified architecture" {
            $invalidArch = $Script:MockFiles
            $invalidArch[0].OSArchitecture = "invalid"
            { Get-InstallationFile -FileParameters $invalidArch } | Should -Throw "Couldn't find release assets for the provided architecture: 'invalid'"
        }

        It "Should throw an error if no checksum file is found" {
            $invalidArch = $Script:MockFiles
            $invalidArch[0].FileFilterRegEx = "(.tar.gz)$" # Change the filter to not include checksum file
            { Get-InstallationFile -FileParameters $invalidArch } | Should -Throw "Some files were not downloaded. Failed to find checksum files for $Script:TestFileName."
        }

        It "Should throw an error if verification fails" {
            Mock Test-Checksum -ModuleName "CommonToolUtilities" -MockWith { return $false }

            { Get-InstallationFile -FileParameters $Script:MockFiles } | Should -Throw "Failed to download asset*"
            $Error[1].Exception.Message | Should -BeLike 'Failed to download assets for "v2.0.0-rc.1". Checksum verification failed.*'
        }

        It "Should throw an error if GitHub API call fails" {
            $errorMessage = "Response status code does not indicate success: 404 (Not Found)."
            Mock Invoke-RestMethod { Throw $errorMessage } -ModuleName "CommonToolUtilities"

            { Get-InstallationFile -FileParameters $Script:MockFiles } | Should -Throw "GitHub API error.*"
        }

        It "Should throw an error if download fails" {
            $errorMessage = "Response status code does not indicate success: 404 (Not Found)."
            Mock Invoke-WebRequest { Throw $errorMessage } -ModuleName "CommonToolUtilities"
            Mock Start-Sleep -ModuleName "CommonToolUtilities"

            { Get-InstallationFile -FileParameters $Script:MockFiles } | Should -Throw "Failed to download asset*"
            Should -Invoke Invoke-WebRequest -Times 3 -Scope It -ModuleName "CommonToolUtilities"
            $Error[1].Exception.Message | Should -BeLike "Failed to download assets for `"v2.0.0-rc.1`". Couldn`'t download `"v2.0.0-rc.1`" release assets*"
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

    Context "Test-FileCheckSum" -Tag "Test-FileCheckSum" {
        BeforeEach {
            $Script:DownloadedFile = "TestDrive:\nerdctl-2.0.0-windows-amd64.tar.gz"
            $Script:ChecksumFile = "TestDrive:\SHA256SUMS"

            Mock Remove-Item -ModuleName "CommonToolUtilities"
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true }
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true } -ParameterFilter { $Path -eq $Script:DownloadedFile }
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true } -ParameterFilter { $Path -eq $Script:ChecksumFile }

            # Create the test file
            New-Item -Path $Script:DownloadedFile -ItemType File -Force | Out-Null
            Set-Content -Path $Script:DownloadedFile -Value "This is a test file."
        }

        AfterEach {
            Get-ChildItem "TestDrive:\" | Remove-Item -Recurse -Force
        }

        It "Should throw an error if the downloaded file does not exist" {
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $false } -ParameterFilter { $Path -eq $Script:DownloadedFile }

            { Test-CheckSum -DownloadedFile $Script:DownloadedFile -ChecksumFile $Script:ChecksumFile } | Should -Throw "Couldn't find source file: `"$Script:DownloadedFile`"."
        }

        It "should verify checksum successfully" {
            Mock Get-FileHash -ModuleName "CommonToolUtilities" -MockWith { return @{ Hash = "SampleHash" } }
            Mock Get-Content -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile } `
                -MockWith { return "SampleHash  nerdctl-2.0.0-windows-amd64.tar.gz" }

            $result = Test-CheckSum -downloadedFile $Script:downloadedFile -ChecksumFile $Script:ChecksumFile
            $result | Should -Be $true

            Should -Invoke Get-FileHash -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter {
                $Path -eq $Script:downloadedFile -and
                $Algorithm -eq 'SHA256'
            }
            Should -Invoke Get-Content -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter {
                $Path -eq $Script:ChecksumFile
            }
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }

        It "should return true when checksums match" {
            # Do an actual file hash
            # Create the checksum file
            $downloadedFileHash = (Get-FileHash -Path $Script:DownloadedFile -Algorithm SHA256).Hash
            New-Item -Path $Script:ChecksumFile -ItemType File -Force | Out-Null
            Set-Content -Path $Script:ChecksumFile -Value (
                $SampleSha256Sum -replace "__CHECKSUM__", $downloadedFileHash)

            $result = Test-CheckSum -DownloadedFile $Script:DownloadedFile -ChecksumFile $Script:ChecksumFile
            $result | Should -Be $true

            # Test regex
            $filePath = "TestDrive:\nerdctl-2.0.0-linux-arm64.tar.gz"
            New-Item -Path $filePath -ItemType File -Force | Out-Null
            Mock Get-FileHash -ModuleName "CommonToolUtilities" -MockWith {
                return @{ Hash = "0286780561d8eb915922b9SaMpLeSHA45abdfeef3e" }
            }
            $result = Test-CheckSum -DownloadedFile $filePath -ChecksumFile $Script:ChecksumFile
            $result | Should -Be $true
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }

        It "should throw and error if invalid hash function is used" {
            $invalidChecksumFile = "TestDrive:\SHA99SUMS"
            { Test-CheckSum -DownloadedFile $Script:DownloadedFile -ChecksumFile $invalidChecksumFile } | `
                Should -Throw "Checksum verification failed for $Script:DownloadedFile. Invalid hash function.*"
        }

        It "should return false when checksums do not match" {
            New-Item -Path $Script:ChecksumFile -ItemType File -Force | Out-Null
            Set-Content -Path $Script:ChecksumFile -Value (
                $SampleSha256Sum -replace "__CHECKSUM__", "InvalidHash")
            $result = Test-CheckSum -DownloadedFile $Script:DownloadedFile -ChecksumFile $Script:ChecksumFile

            $result | Should -Be $false
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }

        It "should return false when downloaded file name does not match SHA256SUMS file names" {
            # Create the checksum file
            New-Item -Path $Script:ChecksumFile -ItemType File -Force | Out-Null
            Set-Content -Path $Script:ChecksumFile -Value "SampleHash  nerdctl-2.0.0-linux-amd64.tar.gz"

            $invalid_download_file = "TestDrive:\invalid-file-name.tar.gz"
            New-Item -Path $invalid_download_file -ItemType File -Force | Out-Null

            { Test-CheckSum -DownloadedFile $invalid_download_file -ChecksumFile $Script:ChecksumFile } | `
                Should -Throw "Checksum verification failed for $invalid_download_file. Checksum not found for `"invalid-file-name.tar.gz`" in $Script:ChecksumFile"
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }

        It "should throw an error for invalid file content format" {
            New-Item -Path $Script:ChecksumFile -ItemType File -Force | Out-Null
            Set-Content -Path $Script:ChecksumFile -Value "sha256sum sample-tool.tar.gz invalid-format"

            { Test-CheckSum -DownloadedFile $Script:DownloadedFile -ChecksumFile $Script:ChecksumFile } | `
                Should -Throw "Checksum verification failed for $Script:DownloadedFile. Invalid checksum file content format in $Script:ChecksumFile. Expected format: <checksum> <filename>."
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }

        It "should catch error when commands fail" {
            Mock Get-FileHash -ModuleName "CommonToolUtilities" -MockWith { Throw "Error" }

            { Test-CheckSum -DownloadedFile $Script:DownloadedFile -ChecksumFile $Script:ChecksumFile } | Should -Throw "Checksum verification failed for $Script:DownloadedFile. Error"
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }
    }

    Context "Test-JSONChecksum" -Tag "Test-JSONChecksum" {
        BeforeEach {
            $Script:DownloadedFile = "TestDrive:\buildkit-v1.0.0.windows-amd64.tar.gz"
            $Script:ChecksumFile = "TestDrive:\sample-tool.provenance.json"
            $Script:SchemaFile = "$PSScriptRoot\TestData\test-schema.json"

            Mock Remove-Item -ModuleName "CommonToolUtilities"
            Mock Test-Json -ModuleName "CommonToolUtilities" -MockWith { return $true }
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true }
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true }
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true } -ParameterFilter { $Path -eq $Script:DownloadedFile }
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true } -ParameterFilter { $Path -eq $Script:ChecksumFile }

            # Create the test file
            New-Item -Path $Script:DownloadedFile -ItemType File -Force | Out-Null
            Set-Content -Path $Script:downloadedFile -Value "This is a test file."

            # To execute
            $MockExtractedFileDigest = [FileDigest]::new(
                "SHA256", (Get-FileHash -Path $Script:DownloadedFile -Algorithm SHA256).Hash)
            $Script:FunctionToCall = { Test-CheckSum `
                    -DownloadedFile $Script:DownloadedFile `
                    -ChecksumFile $Script:ChecksumFile `
                    -JSON `
                    -SchemaFile $Script:SchemaFile `
                    -ExtractDigestScriptBlock { return $MockExtractedFileDigest } `
                    -ExtractDigestArguments @($Script:DownloadedFile, $Script:ChecksumFile)
            }
        }

        AfterEach {
            Get-ChildItem "TestDrive:\" | Remove-Item -Recurse -Force
        }

        It "should verify checksum successfully using in-toto SBOM format" {
            Mock Get-FileHash -ModuleName "CommonToolUtilities" -MockWith { return @{ Hash = "SampleHash" } }
            Mock Get-Content -ModuleName "CommonToolUtilities" `
                -MockWith { return ($SbomJson -replace "__CHECKSUM__", "SampleHash") } `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }

            $result = Test-CheckSum -JSON `
                -DownloadedFile $Script:DownloadedFile `
                -ChecksumFile $Script:ChecksumFile `
                -SchemaFile $Script:SchemaFile

            $result | Should -Be $true

            # Validate Checksum file content
            Should -Invoke Get-Content -ModuleName "CommonToolUtilities" -ParameterFilter { $Path -eq $Script:ChecksumFile }

            # Validate JSON file
            Should -Invoke Test-Json -Times 1 -Scope It -ModuleName "CommonToolUtilities"

            # Assert success
            Should -Invoke Get-FileHash -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter {
                $Path -eq $Script:downloadedFile -and
                $Algorithm -eq 'SHA256'
            }
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter {
                $Path -eq $Script:ChecksumFile
            }
        }

        It "should verify checksum successfully for SBOM formats other than in-toto" {
            Mock Get-FileHash -ModuleName "CommonToolUtilities" -MockWith { return @{ Hash = "SampleHash" } }
            Mock Get-Content -ModuleName "CommonToolUtilities" -MockWith { return ($SbomJson -replace "__CHECKSUM__", "SampleHash") }

            $result = Test-CheckSum -JSON `
                -DownloadedFile $Script:DownloadedFile `
                -ChecksumFile $Script:ChecksumFile `
                -SchemaFile $Script:SchemaFile `
                -ExtractDigestScriptBlock { return ([FileDigest]::new("SHA256", "SampleHash")) } `
                -ExtractDigestArguments @($Script:DownloadedFile, $Script:ChecksumFile)

            $result | Should -Be $true

            # Validate JSON file
            Should -Invoke Get-Content -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter {
                $Path -eq $Script:ChecksumFile
            }
            Should -Invoke Get-Content -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter {
                $Path -eq $Script:SchemaFile
            }
            Should -Invoke Test-Json -Times 1 -Scope It -ModuleName "CommonToolUtilities"

            # Assert success
            Should -Invoke Get-FileHash -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter {
                $Path -eq $Script:downloadedFile -and
                $Algorithm -eq 'SHA256'
            }
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter {
                $Path -eq $Script:ChecksumFile
            }
        }

        It "should verify checksum successfully when ExtractDigestArguments is not provided" {
            Mock Get-FileHash -ModuleName "CommonToolUtilities" -MockWith { return @{ Hash = "SampleHash" } }
            Mock Get-Content -ModuleName "CommonToolUtilities" -MockWith { return ($SbomJson -replace "__CHECKSUM__", "SampleHash") }

            $ScriptNoArgs = { Test-CheckSum -JSON `
                    -DownloadedFile $Script:DownloadedFile `
                    -ChecksumFile $Script:ChecksumFile `
                    -SchemaFile $Script:SchemaFile `
                    -ExtractDigestScriptBlock { return ([FileDigest]::new("SHA256", "SampleHash")) }
            }

            { $ScriptNoArgs } | Should -Not -Throw
        }

        It "should return true when checksums match" {
            # Create the checksum file
            New-Item -Path $Script:ChecksumFile -ItemType File -Force | Out-Null
            Set-Content -Path $Script:ChecksumFile -Value (
                $SbomJson -replace "__CHECKSUM__", $downloadedFileHash)

            $result = & $Script:FunctionToCall

            $result | Should -Be $true
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }

        It "should use custom Test-JSON if command not exists" {
            Mock Get-Command -ModuleName "CommonToolUtilities" -MockWith { return $null }
            Mock Get-Content -ModuleName "CommonToolUtilities" `
                -MockWith { return ($SbomJson -replace "__CHECKSUM__", "SampleHash") } `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }

            # We rely on the absence of the required types (Newtonsoft.Json)
            # to confirm that your fallback logic is being exercised.
            { & $Script:FunctionToCall } | Should -Throw "*Unable to find type*Newtonsoft.Json*"
        }

        It "should throw an error if checksum file does not exist" {
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $false } -ParameterFilter { $Path -eq $Script:ChecksumFile }

            { & $Script:FunctionToCall } | Should -Throw "Couldn't find checksum file: `"$Script:ChecksumFile`"."
        }

        It "should throw an error when checksum file does not use in-toto SBOM format and script block is not provided" {
            $NonInTotoJson = "TestDrive:\non-in-toto.sbom.json"
            New-Item -Path $NonInTotoJson -ItemType File -Force | Out-Null
            Set-Content -Path $NonInTotoJson -Value $OtherSbomFormatJson

            $ToCall = { Test-CheckSum -JSON `
                    -DownloadedFile $Script:DownloadedFile `
                    -ChecksumFile $NonInTotoJson `
                    -SchemaFile $Script:SchemaFile }

            { & $ToCall } | Should -Throw "Invalid checksum JSON format. Expected in-toto SBOM format*"
        }

        It "should throw an error when digest file name is not the same as the downloaded file name" {
            New-Item -Path $Script:ChecksumFile -ItemType File -Force | Out-Null
            Set-Content -Path $Script:ChecksumFile -Value $InvalidFileNameJson

            $ToCall = { Test-CheckSum -JSON `
                    -DownloadedFile $Script:DownloadedFile `
                    -ChecksumFile $Script:ChecksumFile `
                    -SchemaFile $Script:SchemaFile }
            { & $ToCall } | Should -Throw "Downloaded file name does not match the subject name*"
        }

        It "should throw an error if the schema file does not exist" {
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $false } -ParameterFilter { $Path -eq $Script:SchemaFile }

            { & $Script:FunctionToCall } | Should -Throw "Couldn't find the JSON schema file: `"$Script:SchemaFile`"."
        }

        It "should throw an error if the schema file is empty" {
            Mock Get-Content -ModuleName "CommonToolUtilities" -MockWith { return "" } -ParameterFilter { $Path -eq $Script:SchemaFile }

            { & $Script:FunctionToCall } | Should -Throw "Invalid schema file: $Script:SchemaFile. Schema file is empty."
        }

        It "should throw an error if the JSON file is not valid" {
            Mock Get-Content -ModuleName "CommonToolUtilities" -MockWith { return "Test data" }

            # Test-Json returns true if the JSON is valid, otherwise it throws an error
            Mock Test-Json -ModuleName "CommonToolUtilities" -MockWith { Throw "Error" }

            # Test the function
            { & $Script:FunctionToCall } | Should -Throw "Error validating JSON checksum file. Error"
        }

        It "should throw an error if script block throws an error" {
            # ParentContainsErrorRecordException: Exception calling "Invoke" with "1" argument(s): "Error message"
            { Test-CheckSum -DownloadedFile $Script:DownloadedFile -ChecksumFile $Script:ChecksumFile -JSON -SchemaFile $Script:SchemaFile -ExtractDigestScriptBlock { (Throw "Error message") } | `
                    Should -Throw "Invalid script block output*"
            }
        }

        It "should throw an error if ExtractedFileDigest is not a FileDigest object" {
            Mock Get-Content -ModuleName "CommonToolUtilities" -MockWith { return "Test data" }
            Mock Get-FileHash -ModuleName "CommonToolUtilities" -MockWith { return "SampleHash" }

            $InvalidOutputFunc = { Test-CheckSum -JSON `
                    -DownloadedFile $Script:DownloadedFile `
                    -ChecksumFile $Script:ChecksumFile `
                    -SchemaFile $Script:SchemaFile `
                    -ExtractDigestScriptBlock { return } `
                    -ExtractDigestArguments @($Script:DownloadedFile, $Script:ChecksumUri)
            }
            { & $InvalidOutputFunc } | Should -Throw 'Invalid value. Requires a value with type "FileDigest".'
        }

        It "should throw and error if invalid hash function is used" {
            Mock Get-Content -ModuleName "CommonToolUtilities" -MockWith { return "Test data" }

            $InvalidAlgo = { Test-CheckSum `
                    -DownloadedFile $Script:DownloadedFile `
                    -ChecksumFile $Script:ChecksumFile `
                    -JSON `
                    -SchemaFile $Script:SchemaFile `
                    -ExtractDigestScriptBlock { return ([FileDigest]::new("SHA99", "SampleHash") ) } `
                    -ExtractDigestArguments @($Script:DownloadedFile, $Script:ChecksumUri)
            }

            { & $InvalidAlgo } | Should -Throw `
                "Checksum verification failed for $Script:DownloadedFile. Invalid hash function, `"sha99`".*"
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }

        It "should return false when checksums do not match" {
            Mock Get-Content -ModuleName "CommonToolUtilities" -MockWith { return "Test data" }

            # Test the function
            $result = Test-CheckSum `
                -DownloadedFile "TestDrive:\sample-tool.tar.gz" `
                -ChecksumFile $Script:ChecksumFile `
                -JSON `
                -SchemaFile $Script:SchemaFile `
                -ExtractDigestScriptBlock { return ([FileDigest]::new("SHA256", "InvalidHash")) } `
                -ExtractDigestArguments @($Script:DownloadedFile, $Script:ChecksumUri)
            $result | Should -Be $false

            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }

        It "should catch error when commands fail" {
            Mock Get-Content -ModuleName "CommonToolUtilities" -MockWith { return "Test data" }
            Mock Get-FileHash -ModuleName "CommonToolUtilities" -MockWith { Throw "Error" }

            # Test the function
            { & $Script:FunctionToCall } | Should -Throw "Checksum verification failed for $Script:DownloadedFile. Error"
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" `
                -ParameterFilter { $Path -eq $Script:ChecksumFile }
        }
    }

    Context "Install-RequiredFeature" -Tag "Install-RequiredFeature" {
        BeforeAll {
            $obj = New-MockObject -Type 'System.Diagnostics.Process' -Properties @{ ExitCode = 0 }
            Mock Invoke-ExecutableCommand -ModuleName "CommonToolUtilities" -MockWith { return $obj }
            Mock Add-FeatureToPath -ModuleName "CommonToolUtilities"
            Mock New-Item -ModuleName "CommonToolUtilities"
            Mock Remove-Item -ModuleName "CommonToolUtilities"
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $true }
        }

        It "Should successfully install tool" {
            Mock Test-Path -ModuleName "CommonToolUtilities" -MockWith { return $false } -ParameterFilter { $Path -eq $params.InstallPath }

            $params = @{
                Feature     = "containerd"
                InstallPath = "$ProgramFiles\Containerd"
                SourceFile  = "$DownloadPath\containerd-binaries.tar.gz"
                EnvPath     = "$ProgramFiles\Containerd\bin"
                cleanup     = $true
            }

            Install-RequiredFeature @params

            #  Check that the dir is created if it does not exist
            Should -Invoke New-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter { ($Path -eq $params.InstallPath) }

            # Test that the file is untar-ed
            Should -Invoke Invoke-ExecutableCommand -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter { ($Executable -eq 'tar.exe') -and ($Arguments -eq "-xf `"$($params.SourceFile)`" -C `"$($params.InstallPath)`"") }

            # Test that method to add feature to path is called
            Should -Invoke Add-FeatureToPath -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter { ($Feature -eq $params.Feature) -and ($Path -eq $params.EnvPath) }

            # Check that clean up is done on completion
            Should -Invoke Remove-Item -Times 1 -Scope It -ModuleName "CommonToolUtilities" -ParameterFilter { $Path -eq $params.SourceFile }
        }

        It "should not remove items if cleanup is false" {
            $params = @{
                Feature     = "containerd"
                InstallPath = "$ProgramFiles\Containerd"
                SourceFile  = "$DownloadPath\containerd-binaries.tar.gz"
                EnvPath     = "$ProgramFiles\Containerd\bin"
                cleanup     = $false
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
                Feature     = "containerd"
                InstallPath = "$ProgramFiles\Containerd"
                SourceFile  = "$DownloadPath\containerd-binaries.tar.gz"
                EnvPath     = "$ProgramFiles\Containerd\bin"
                cleanup     = $false
            }

            { Install-RequiredFeature @params } | Should -Throw "Couldn't expand archive file(s) $($params.SourceFile).*"
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
                    $null -eq $Path -and
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

    Context "Uninstall-ProgramFiles" -Tag "Uninstall-ProgramFiles" {
        BeforeAll {
            New-Item -Path "TestDrive\Buildkit" -ItemType "Directory" -Force | Out-Null
        }

        it "Should successfully remove dir" {
            Mock Remove-Item -ModuleName 'CommonToolUtilities'

            { Uninstall-ProgramFiles -Path "$ENV:ProgramData\Buildkit" } | Should -Not -Throw
        }

        it "Should not throw error if directory does not exist" {
            Mock Get-Item -ModuleName 'CommonToolUtilities' -ParameterFilter { $Path -eq "TestDrive\Buildkit" } -MockWith { return }

            { Uninstall-ProgramFiles -Path "$ENV:ProgramData\Buildkit" } | Should -Not -Throw
        }

        it "Should not throw an error if removing programdata fails with access denied" {
            $accessDeniedErr = "Remove-Item: Access to the path 'C:\ProgramData\Buildkit\dummy\testfile.txt' is denied."
            Mock Remove-Item -ModuleName 'CommonToolUtilities' -MockWith { Throw $accessDeniedErr }

            { Uninstall-ProgramFiles -Path "TestDrive\Buildkit" } | Should -Not -Throw
            $Error[0].Exception.Message | Should -BeLike "Failed to delete directory: 'TestDrive\Buildkit'. Access to path denied. *"
        }

        it "Should not throw an error if removing programdata fails" {
            Mock Remove-Item -ModuleName 'CommonToolUtilities' -MockWith { Throw "Error" }

            { Uninstall-ProgramFiles -Path "TestDrive\Buildkit" } | Should -Not -Throw
            $Error[0].Exception.Message | Should -BeExactly "Failed to delete directory: 'TestDrive\Buildkit'. Error"
        }
    }
}