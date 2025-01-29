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

.PARAMETER ReleaseNotesPath
Path to the release notes. Defaults to empty string.
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
    [String]$ReleaseNotesPath
)

Set-Variable -Name ManifestPath -Value $ManifestPath -Scope Script -Force
Set-Variable -Name Version -Value $Version -Scope Script -Force
Set-Variable -Name ReleaseNotesPath -Value $ReleaseNotesPath -Scope Script -Force
Set-Variable -Name Prerelease -Value $Prerelease -Scope Script -Force


function Update-CTKModuleManifest {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param()

    begin {
        $moduleVersion = "$Version-$Prerelease"
        $WhatIfMessage = "Module version will be updated to version $Version"
    }

    process {
        if ($PSCmdlet.ShouldProcess($ManifestPath, $WhatIfMessage)) {
            Write-Information -MessageData "Updating module version to '$moduleVersion' in manifest file '$ManifestPath'" -InformationAction Continue

            # Get release notes
            $ReleaseNotes = if ($ReleaseNotesPath) { Get-Content -Path $ReleaseNotesPath -Raw } else { '' }
            $ReleaseNotes = if ($ReleaseNotesPath) { Get-Content -Path $ReleaseNotesPath -Raw } else { '' }

            $ModuleTags = @("Windows Containers", "Containers-Toolkit", "containerd", "buildkit", "nerdctl", "cni")
            $params = @{
                Path          = $manifestPath
                ModuleVersion = $Version
                LicenseUri    = "https://github.com/microsoft/containers-toolkit/blob/v$moduleVersion/LICENSE"
                ReleaseNotes  = $ReleaseNotes
                Prerelease    = $Prerelease
                Tags          = $ModuleTags
            }
            Update-ModuleManifest @params

            # Test the manifest script is valid
            Test-ModuleManifest -Path $manifestPath | Out-Null

            return $moduleVersion
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

Update-CTKModuleManifest -Confirm:$false
