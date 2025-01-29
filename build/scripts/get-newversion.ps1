###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

<#
.SYNOPSIS
Returns the new version number based on the current version and the release type.

.PARAMETER ReleaseType
The type of release to perform. Options: 'major', 'minor', 'patch'
Defaults to 'patch'
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

function Get-NewVersion ($ManifestPath, $ReleaseType) {
    [version]$currentVersion = (Get-Module -ListAvailable -Name $ManifestPath).Version

    $Major = $currentVersion.Major
    $Minor = $currentVersion.Minor
    $Build = $currentVersion.Build

    switch ($ReleaseType) {
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
            Write-Error "Invalid release type specified: '$ReleaseType'"
            exit 1
        }
    }

    return (New-Object Version -ArgumentList $major, $minor, $build).ToString()
}

Get-NewVersion -ManifestPath $ManifestPath -ReleaseType $ReleaseType
