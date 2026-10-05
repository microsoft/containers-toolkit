<#
This scripts gets the new version number based on the current release branch

.PARAMETER ReleaseBranch
The release branch to check for the new version number.
Release branches are expected to be in the format 'release/X.Y.Z' or 'release/X.Y.Z-alpha'."

.RETURN
The new version number based on the current release branch.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ReleaseBranch
)

$ErrorActionPreference = "Stop"

$ValidationError = "Invalid version format in release branch: '$ReleaseBranch'. Expected format is 'release/X.Y.Z' or 'release/X.Y.Z-alpha'."

# Validate the release branch
if ($ReleaseBranch -notmatch '^(release/.*)$') {
    Write-Error $ValidationError
    exit 1
}

# Split the release branch to get the version number
# Example: release/1.2.3-alpha
$VersionSplit = ($ReleaseBranch -replace 'release/', '') -split "-"
Write-Debug "VersionSplit ($($VersionSplit.Count)): $VersionSplit"

# Set the version number based on the split
$version = [Version]($VersionSplit[0] -replace 'v', '')
switch ($VersionSplit.Count) {
    1 {
        $ReleaseVersion = "$version"
    }
    2 {
        $PrereleaseTag = $VersionSplit[1].ToLower()
        $ReleaseVersion = "$version-$PrereleaseTag"
    }
    Default {
        Write-Error $ValidationError
    }
}

# Generate the version object
$result = [PSCustomObject]@{
    Version        = "$version"
    Prerelease     = $PrereleaseTag
    ReleaseVersion = $ReleaseVersion
    ReleaseTag     = "v$ReleaseVersion"
}
Write-Debug $result
return $result
