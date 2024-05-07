###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

<#
.SYNOPSIS
Updates the version of the containers-toolkit module in the module manifest file.

The script is a PowerShell script that takes two parameters:
.PARAMETER ManifestPath
The path to the module manifest file.
Defaults to the first containers-toolkit.psd1 file found in the repository.

.PARAMETER ReleaseType
The type of release to perform.
Defaults to 'patch'.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String]$ManifestPath = (Get-ChildItem -Recurse -Filter "containers-toolkit.psd1").FullName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('major', 'minor', 'patch')]
    [String]$ReleaseType = 'patch'
)

$Script:ManifestPath = $ManifestPath
$Script:ReleaseType = $ReleaseType

function Get-NewVersion {
    [version]$currentVersion = (Get-Module -ListAvailable -Name $Script:ManifestPath).Version

    $Major = $currentVersion.Major
    $Minor = $currentVersion.Minor
    $Build = $currentVersion.Build

    switch ($Script:ReleaseType) {
        # MAJOR version is increased for incompatible API changes.
        'major' {
            $Major++
            $Minor = 0
            $Build = 0
        }
        # MINOR version is increased for backward-compatible feature additions.
        'minor' {
            $Minor++
            $Build = 0
        }
        # PATCH version is increased for backward-compatible bug fixes.
        'patch' {
            $Build++
        }
        Default {
            Write-Error "Invalid release type specified: '$Script:ReleaseType'"
            exit 1
        }
    }

    return (New-Object Version -ArgumentList $major, $minor, $build).ToString()
}

function Update-CTKModuleManifest {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param()

    begin {
        $NewSemVer = Get-NewVersion
        $WhatIfMessage = "Module version will be updated to version $NewSemVer"
    }

    process {
        if ($PSCmdlet.ShouldProcess($Script:ManifestPath, $WhatIfMessage)) {
            $Params = @{
                Path          = $manifestPath
                ModuleVersion = $NewSemVer
                LicenseUri    = "https://github.com/microsoft/containers-toolkit/blob/v$NewSemVer/LICENSE"
            }
            Update-ModuleManifest @Params

            # Test the manifest script is valid
            Test-ModuleManifest -Path $manifestPath | Out-Null

            return $NewSemVer
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

Update-CTKModuleManifest -Confirm:$false
