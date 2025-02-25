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

.PARAMETER SourceFile
The path to the file to generate a hash for.

.PARAMETER Algorithm
The hash algorithm to use. Defaults to SHA256.
#>

[CmdletBinding()]
param (
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String]$SourceFile,
    [String]$Algorithm = "SHA256"
)


$fileName = Split-Path -Path $SourceFile -Leaf

# Compute archived file Hash
$file_hash = Get-FileHash $SourceFile -Algorithm $Algorithm | Select-Object -ExpandProperty Hash

# Dump to file
$sha_filename = "$SourceFile.$Algorithm"
Set-Content -Path $sha_filename -Value "$file_hash`t$fileName"

Write-Host "Created hash file '$sha_filename'"
