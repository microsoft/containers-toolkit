<#
.SYNOPSIS
    Get the new version number for the release.

.DESCRIPTION
    Given a release version, this script will recursively check for a valid version number
    by checking the PowerShell Gallery.

.PARAMETER Version
    The version number to check for. This should be a valid semantic version number.
    Example: 1.2.3

.PARAMETER Prerelease
    The pre-release tag to check for. This should be a valid semantic version pre-release tag.
    Example: alpha2, beta0, rc0

.PARAMETER ReleaseType
    The type of release to check for. This should be one of the following:
    major, minor, patch

.PARAMETER MaxPrerelease
    The maximum number of pre-release tags to check for. This is used to limit the number of
    iterations when checking for a valid version number. Default is 20.
    For example, if the current version is 1.2.3-alpha2 and the next version is 1.2.3-alpha3,
    this will check for 20 pre-release tags: alpha3, alpha4, ..., alpha20.

    When the maximum number of pre-release tags is reached, the script will stop checking and increment
    the version number based on the release type.

    When MaxPrerelease is set to 0 (or less), the script will not check for pre-release tags and will
    increment the version number based on the release type.

.EXAMPLE
    .\get-newversion.ps1 -Version 1.2.3 -Prerelease alpha2 -ReleaseType minor

    This will check for the next version number based on the provided version, pre-release tag, and release type.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [version]$Version,

    [Parameter(Mandatory = $false)]
    [string]$Prerelease,

    [Parameter(Mandatory = $true)]
    [ValidateSet("major", "minor", "patch")]
    [string]$ReleaseType,

    [Parameter(Mandatory = $false)]
    [int]$MaxPrerelease = "20"
)

$ErrorActionPreference = "Stop"

function Update-SemverTag($Semver, $ReleaseType) {
    switch ($ReleaseType) {
        "major" { return [version]::new($Semver.Major + 1, 0, 0) }
        "minor" { return [version]::new($Semver.Major, $Semver.Minor + 1, 0) }
        "patch" { return [version]::new($Semver.Major, $Semver.Minor, $Semver.Build + 1) }
    }
}

function Get-PrereleaseValue($PrereleaseTag) {
    $match = [regex]::Match($PrereleaseTag, "(.*?)(\d+)$")
    return [int]$match.Groups[2].Value + 1
}

function Update-Prerelease($PrereleaseTag) {
    $match = [regex]::Match("$PrereleaseTag", "(.*?)(\d+)$")
    $prefix = [string]$match.Groups[1].Value
    $number = [int]$match.Groups[2].Value
    return "$prefix" + "$($number + 1)"
}

function Test-ModuleVersion($ModuleVersion) {
    $PublishedVersions = Find-Module -AllowPrerelease `
        -Name containers-toolkit `
        -RequiredVersion "$ModuleVersion" `
        -ErrorAction SilentlyContinue | Where-Object { $_.Version -eq $ModuleVersion }
    return $PublishedVersions
}

while ($true) {
    $ModuleVersion = "${Version}-${Prerelease}".TrimEnd("-")
    Write-Host "Checking for module version: $ModuleVersion" -ForegroundColor Magenta

    $PublishedVersions = Test-ModuleVersion $ModuleVersion
    if (-not $PublishedVersions) {
        Write-Host "Module version $ModuleVersion is not published." -ForegroundColor Magenta
        return $ModuleVersion
    }

    # Find a pre-release tag that is not published
    while ($Prerelease -and ($MaxPrerelease -gt 0) -and ($PublishedVersions.Version -match "$Prerelease")) {
        $Prerelease = Update-Prerelease $Prerelease
        $ModuleVersion = "${Version}-${Prerelease}"

        Write-Host "Incrementing pre-release tag: $ModuleVersion" -ForegroundColor Magenta
        $PublishedVersions = Test-ModuleVersion $ModuleVersion
        if (-not $PublishedVersions) {
            Write-Host "Module version $ModuleVersion is not published." -ForegroundColor Magenta
            return $ModuleVersion
        }

        $MaxPrerelease -= 1
    }

    $Version = Update-SemverTag $Version $ReleaseType
}
