<#
    This script generates release notes for the current version of the project.
    It uses a template file and replaces placeholders with actual values.

    .PARAMETER ReleaseTag
    The release tag to be used in the release notes. This is a mandatory parameter.

    .PARAMETER ReleaseNotesTemplate
    The path to the release notes template file. This is an optional parameter.
    If not provided, the script will search for a file named "release-notes-template.md" in the current directory and its subdirectories.

    .PARAMETER Destination
    The destination path where the generated release notes will be saved. This is an optional parameter.
    If not provided, the script will save the release notes in the root directory of the project with the name "release-note.txt".
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)]
    [String]$ReleaseTag,

    [Parameter(Mandatory = $False)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String]$Template = (Get-ChildItem -Recurse -Filter "release-notes-template.md").FullName,

    [Parameter(Mandatory = $False)]
    [String]$Destination
)

$ROOT_DIR = (Get-Item "$PSScriptRoot").Parent.Parent.Parent.FullName
Write-Host "Root directory: $ROOT_DIR"

Write-Debug "Release tag: $ReleaseTag"
Write-Debug "Release notes template: $Template"

# Replace the placeholder with the actual release tag
$trimmedTag = "$releaseTag".trim("v")
$releaseNotes = [IO.File]::ReadAllText("$Template")
$releaseNotes = $releaseNotes -replace "__MODULE_VERSION__", "$trimmedTag"
$releaseNotes = $releaseNotes -replace "__RELEASE_TAG__", "$releaseTag"

# Add the AllowPrerelease flag if this is a pre-release version
$isPrelease = ($trimmedTag -split "-").Count -gt 1
if ($isPrelease) {
    Write-Debug "Pre-release version detected: $trimmedTag"
    $releaseNotes = $releaseNotes -replace "__ALLOW_PRERELEASE__", "-AllowPrerelease"
}
else {
    $releaseNotes = $releaseNotes -replace " __ALLOW_PRERELEASE__", ""
}

# Set destination path
if ([String]::IsNullOrEmpty($Destination)) {
    $Destination = "$ROOT_DIR"
}

# Generate the output file name for the release notes
$RELEASENOTES_PATH = Join-Path -Path "$Destination" -ChildPath "release-note.txt"

# Dump to file
Write-Host "Publishing release notes to '$RELEASENOTES_PATH'"
$releaseNotes | Out-File -FilePath "$RELEASENOTES_PATH" -Encoding utf8 -Force
