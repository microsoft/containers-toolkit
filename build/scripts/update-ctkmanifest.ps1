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

.PARAMETER Version
The new version number to update the module manifest file to.

.PARAMETER Prerelease
Pre-release version string. Defaults to empty string.
Examples of supported Prerelease string are: -alpha, -alpha1, -BETA, -update20171020

.PARAMETER ReleaseNotes
Release notes for the new version. Defaults to empty string.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String]$ManifestPath = (Get-ChildItem -Recurse -Filter "containers-toolkit.psd1").FullName,

    [Parameter(Mandatory = $true)]
    [String]$Version,

    [Parameter(Mandatory = $false)]
    [String]$Prerelease,

    [Parameter(Mandatory = $false)]
    [String]$ReleaseNotes
)

$Script:ManifestPath = $ManifestPath
$Script:Version = $Version
$Script:ReleaseNotes = $ReleaseNotes
$Script:Prerelease = $Prerelease


function Update-CTKModuleManifest {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param()

    begin {
        $WhatIfMessage = "Module version will be updated to version $Script:Version"
    }

    process {
        if ($PSCmdlet.ShouldProcess($Script:ManifestPath, $WhatIfMessage)) {
            $Params = @{
                Path          = $manifestPath
                ModuleVersion = $Script:Version
                LicenseUri    = "https://github.com/microsoft/containers-toolkit/blob/v$Script:Version/LICENSE"
                ReleaseNotes  = $Script:ReleaseNotes
                Prerelease    = $Script:Prerelease
            }

            Update-ModuleManifest @Params

            # Test the manifest script is valid
            Test-ModuleManifest -Path $manifestPath | Out-Null
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

Update-CTKModuleManifest -Confirm:$false
