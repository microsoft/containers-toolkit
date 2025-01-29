###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

<#
.SYNOPSIS
Generates a hash for the specified file.

.PARAMETER SourcePath
The path to the file/folder to generate a hash for.
    1. To generate a hash for a file, specify the full path to the file.
    2. To generate a hash for all files in a folder, specify the full path to the folder and
       use the wildcard '*'. E.g. 'C:\path\to\folder\*'.

.PARAMETER ReleaseTag
The release tag to use for the output file name.

.PARAMETER Algorithm
The hash algorithm to use. Defaults to SHA256.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [String]$SourcePath,
    [Parameter(Mandatory = $true)]
    [String]$ReleaseTag,
    [String]$Algorithm = "SHA256"
)


Write-Host "Generating hash: { Source: '$SourcePath', Algorithm '$Algorithm' }..." -ForegroundColor Cyan

# Validate source path
if (Test-Path -Path $SourcePath -PathType Container) {
    # If the source path is a directory, check if it contains files.
    if (-not (Get-ChildItem -Path $SourcePath -File -ErrorAction SilentlyContinue)) {
        Write-Host "Source path is a directory but contains no files."
        exit 1
    }
    if ($SourcePath -notmatch "(\*)$") {
        # If the source path is a directory, append wildcard to the path.
        # Get-FileHash supports wildcards, so we append '*' to the path,
        # to include all files in the directory.
        Write-Debug "Source path is a directory. Appending wildcard to the path."
        $SourcePath = Join-Path -Path $SourcePath -ChildPath "*"
    }
}

# Generate the output file name for the hash
$sha_filename = "containers-toolkit-$ReleaseTag.$Algorithm"

# Compute file Hash and dump to file
Get-FileHash -Algorithm $Algorithm "$SourcePath" -ErrorAction Continue | `
    ForEach-Object { "$($_.Hash)  $($_.Path | Split-Path -Leaf)" } | `
    Tee-Object -FilePath $sha_filename | Out-Null

Write-Host "Created hash file '$sha_filename'" -ForegroundColor Green
