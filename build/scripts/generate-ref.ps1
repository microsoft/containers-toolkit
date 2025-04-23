# Generate the command-reference.md file

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String]$ManifestPath = (Get-ChildItem -Recurse -Filter "containers-toolkit.psd1").FullName
)

# Get the functions exported by the module
$ExportedFunctions = (Get-Module $ManifestPath -ListAvailable).ExportedFunctions

# Tools
$tools = @(
    "ContainerTools",
    "BuildKit",
    "Containerd",
    "Nerdctl",
    "WinCNIPlugin"
)

# The markdown to be written to the command-reference.md file
$mdString = @"
# Command Reference

## Table of Contents
"@

# Parse the exported functions and generate the markdown
foreach ($tool in $tools) {
    $result = $ExportedFunctions.Keys | Where-Object { $_ -match "$tool" } | ForEach-Object {
        "- [$_](./About/$($_).md)"
    }
    $heading = if ($tool -eq "ContainerTools") {
        "General"
    } else {
        "$tool"
    }
    $mdString += "`n- $heading`n  $($result -join "`n  ")"
}

# Write the markdown to the file
$parentPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$REF_FILE = Join-Path -Path $parentPath -ChildPath "docs\command-reference.md"
Set-Content -Path $REF_FILE -Value $mdString -Force -Encoding UTF8

Write-Host "Command reference file generated at: $REF_FILE" -ForegroundColor Green
Write-Host "Please review the generated file and make any necessary adjustments." -ForegroundColor Green