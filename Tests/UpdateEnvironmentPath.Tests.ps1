###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


Describe "UpdateEnvironmentPath.psm1" { 
    BeforeAll {
        $RootPath = Split-Path -Parent $PSScriptRoot
        $ModuleParentPath = Join-Path -Path $RootPath -ChildPath 'Containers-Toolkit'
        Import-Module -Name "$ModuleParentPath\Private\UpdateEnvironmentPath.psm1" -Force

        # Original enviromnent values
        $originalUserPathString = $ENV:Path
        $originalSysPathString = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    }

    Context "Add feature from env path" -Tag "Update-EnvironmentPath" {
        It "Should successfully add the tool to the System environment path" {
            # Arrange
            $tool = "MyTool"
            $path = "TestDrive:\TestTool"
            $pathType = "System"
            $action = "Add"

            # Act
            $result = Update-EnvironmentPath -Tool $tool -Path $path -PathType $pathType -Action $action

            # Assert
            $result | Should -BeLike "*$path*"

            # should not update actual values during testing
            [System.Environment]::GetEnvironmentVariable("Path", "Machine") | Should -Be $originalSysPathString
            $env:Path | Should -Be $originalUserPathString
        }

        It "Should successfully add the tool to the User environment path" {
            # Arrange
            $tool = "MyTool"
            $path = "TestDrive:\TestTool"
            $pathType = "User"
            $action = "Add"

            # Act
            $result = Update-EnvironmentPath -Tool $tool -Path $path -PathType $pathType -Action $action

            # Assert
            $result | Should -BeLike "*$path*"

            # should not update actual values during testing
            [System.Environment]::GetEnvironmentVariable("Path", "Machine") | Should -Be $originalSysPathString
            $env:Path | Should -Be $originalUserPathString
        }
    }

    Context "Remove feature from env path" -Tag "Update-EnvironmentPath" {
        It "Should successfully remove the tool to the System environment path" {
            # Arrange
            $tool = "MyTool"
            $path = "TestDrive:\TestTool"
            $pathType = "System"
            $action = "Remove"

            # Act
            $result = Update-EnvironmentPath -Tool $tool -Path $path -PathType $pathType -Action $action

            # Assert
            $result | Should -Not -BeLike "*$path*"

            # should not update actual values during testing
            [System.Environment]::GetEnvironmentVariable("Path", "Machine") | Should -Be $originalSysPathString
            $env:Path | Should -Be $originalUserPathString
        }

        It "Should remove the tool from the User environment path" {
            # Arrange
            $tool = "MyTool"
            $path = "TestDrive:\TestTool"
            $pathType = "User"
            $action = "Remove"

            # Act
            $result = Update-EnvironmentPath -Tool $tool -Path $path -PathType $pathType -Action $action

            # Assert
            $result | Should -Not -BeLike "*$path*"

            # should not update actual values during testing
            [System.Environment]::GetEnvironmentVariable("Path", "Machine") | Should -Be $originalSysPathString
            $env:Path | Should -Be $originalUserPathString
        }
    }

    Context "Invalid parameters" -Tag "Update-EnvironmentPath" {
        It "Should throw an error for an invalid Action" {
            # Arrange
            $tool = "MyTool"
            $path = "TestDrive:\TestTool"
            $pathType = "User"
            $action = "Invalid"

            # Act & Assert
            { Update-EnvironmentPath -Tool $tool -Path $path -PathType $pathType -Action $action } | Should -Throw
        }
    
        It "Should throw an error for an invalid PathType" {
            # Arrange
            $tool = "MyTool"
            $path = "TestDrive:\TestTool"
            $pathType = "Invalid"
            $action = "Add"
    
            # Act & Assert
            { Update-EnvironmentPath -Tool $tool -Path $path -PathType $pathType -Action $action } | Should -Throw
        }
    }
}
