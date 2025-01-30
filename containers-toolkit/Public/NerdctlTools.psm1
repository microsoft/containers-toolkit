###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

using module "..\Private\CommonToolUtilities.psm1"

$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force

function Get-NerdctlLatestVersion {
    $latestVersion = Get-LatestToolVersion -Repository "containerd/nerdctl"
    return $latestVersion
}

function Get-NerdctlDependencies($dependencies) {
    if (!$dependencies) {
        return
    }

    $nerdctlDependencies = @("Containerd", "Buildkit", "WinCNIPlugin")
    if ($Dependencies -and $Dependencies -contains "All") {
        $dependencies = $nerdctlDependencies
    }

    foreach ($dependency in $dependencies) {
        if (-not ($nerdctlDependencies -contains $dependency)) {
            Throw "Invalid dependency option: $dependency. Allowed options: All, Containerd, Buildkit, WinCNIPlugin"
        }
    }

    return $dependencies
}

function Install-NerdctlDependencies {
    param(
        [String[]]$Dependencies,
        [string]$OsArch,
        [Switch]$Force
    )

    foreach ($dependency in $Dependencies) {
        $InstallCommand = "Install-$dependency"
        try {
            & $InstallCommand -OSArchitecture $OsArch -Force:$Force -Confirm:$false
        }
        catch {
            Write-Error "Installation failed for $dependency. $_"
        }
    }
}

function Install-Nerdctl {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [string]
        [parameter(HelpMessage = "nerdctl version to use. Defaults to 'latest'")]
        $Version = "latest",

        [String]
        [parameter(HelpMessage = "Path to install nerdctl. Defaults to ~\program files\nerdctl")]
        $InstallPath = "$Env:ProgramFiles\nerdctl",

        [String]
        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        $DownloadPath = "$HOME\Downloads",

        [String[]]
        [parameter(HelpMessage = "Specify nerdctl dependencies (All, Containerd, Buildkit, WinCNIPlugin) to install")]
        $Dependencies,

        [string]
        [Parameter(HelpMessage = 'OS architecture to download files for. Default is $env:PROCESSOR_ARCHITECTURE')]
        [ValidateSet('amd64', '386', "arm", "arm64")]
        $OSArchitecture = $env:PROCESSOR_ARCHITECTURE,

        [Switch]
        [parameter(HelpMessage = "Installs nerdctl (and its dependecies if specified) even if the tool already exists at the specified path")]
        $Force
    )

    begin {
        # Check if Containerd is alread installed
        $isInstalled = -not (Test-EmptyDirectory -Path "$InstallPath")

        $toInstall = @("nerdctl")

        $dependencies = Get-NerdctlDependencies -Dependencies $dependencies
        if ($dependencies) {
            $toInstall += $dependencies
        }

        $WhatIfMessage = "nerdctl will be installed at '$installPath'"
        if ($isInstalled) {
            $WhatIfMessage = "nerdctl will be uninstalled from and reinstalled at '$installPath'"
        }
        if ($dependencies) {
            <# Action when this condition is true #>
            $WhatIfMessage = "nerdctl and its dependencies (Containerd, Buildkit, WinCNIPlugin) will be installed"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            # Check if tool already exists at specified location
            if ($isInstalled) {
                $errMsg = "nerdctl already exists at '$InstallPath' or the directory is not empty."
                Write-Warning $errMsg

                # Uninstall if tool exists at specified location. Requires user consent
                try {
                    Uninstall-Nerdctl -Path "$InstallPath" -Confirm:$false -Force:$Force | Out-Null
                }
                catch {
                    Throw "nerdctl installation failed. $_"
                }
            }

            # Get nerdctl version to install
            if (!$Version) {
                $Version = Get-NerdctlLatestVersion
            }
            $Version = $Version.TrimStart('v')

            Write-Output "Downloading and installing nerdctl v$version at $InstallPath"

            # Download files
            $downloadParams = @{
                ToolName           = "nerdctl"
                Repository         = "containerd/nerdctl"
                Version            = $version
                OSArchitecture     = $OSArchitecture
                DownloadPath       = $DownloadPath
                ChecksumSchemaFile = $null
                FileFilterRegEx    = $null
            }
            $downloadParamsProperties = [FileDownloadParameters]::new(
                $downloadParams.ToolName,
                $downloadParams.Repository,
                $downloadParams.Version,
                $downloadParams.OSArchitecture,
                $downloadParams.DownloadPath,
                $downloadParams.ChecksumSchemaFile,
                $downloadParams.FileFilterRegEx
            )
            $sourceFile = Get-InstallationFile -FileParameters $downloadParamsProperties

            # Untar and install tool
            $params = @{
                Feature     = "nerdctl"
                InstallPath = $InstallPath
                SourceFile  = $sourceFile
                EnvPath     = $InstallPath
                cleanup     = $true
            }
            Install-RequiredFeature @params

            Write-Output "nerdctl v$version successfully installed at $InstallPath"
            Write-Output "For nerdctl usage: run 'nerdctl -h'`n"

            # Install dependencies
            Write-Output "Installing nerdctl dependencies: $toinstall"
            Install-NerdctlDependencies -Dependencies $dependencies -OsArch $OSArchitecture -Force:$true
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}


# TODO: Implement this
function Initialize-NerdctlToml {
    param(
        [parameter(HelpMessage = "Toml path. Defaults to ~\AppData\nerdctl\nerdctl.toml")]
        [String]$Path = "$env:APPDATA\nerdctl\nerdctl.toml"
    )

    # https://github.com/containerd/nerdctl/blob/main/docs/config.md
    $nerdctlConfig = @"
{}
"@

    $nerdctlConfig | Set-Content $Path -Force
}

function Uninstall-Nerdctl {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [parameter(HelpMessage = "nerdctl path")]
        [String]$Path = "$Env:ProgramFiles\nerdctl",

        [parameter(HelpMessage = "Remove all program data for nerdctl")]
        [Switch] $Purge,

        [parameter(HelpMessage = "Bypass confirmation to uninstall nerdctl")]
        [Switch] $Force
    )

    begin {
        $tool = 'nerdctl'
        if (!$Path) {
            $Path = Get-DefaultInstallPath -Tool "nerdctl"
        }

        $WhatIfMessage = "nerdctl will be uninstalled from '$Path'."
        if ($Purge) {
            $WhatIfMessage += " nerdctl program data will also be removed."
        }
        else {
            $WhatIfMessage += " nerdctl program data won't be removed. To remove program data, run 'Uninstall-Nerdctl' command without -Purge flag."
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            if (Test-EmptyDirectory -Path "$path") {
                Write-Output "$tool does not exist at '$Path' or the directory is empty"
                return
            }

            $consent = $force
            if (!$ENV:PESTER) {
                $consent = $force -or $PSCmdlet.ShouldContinue($Path, 'Are you sure you want to uninstall nerdctl?')
            }

            if (!$consent) {
                Write-Warning "$tool uninstallation cancelled."
                return
            }

            Write-Warning "Uninstalling preinstalled $tool at the path '$path'.`n$WhatIfMessage"
            try {
                Uninstall-NerdctlHelper -Path "$path" -Purge:$Purge
            }
            catch {
                Throw "Could not uninstall $tool. $_"
            }
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Uninstall-NerdctlHelper {
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory = $true, HelpMessage = "nerdctl path")]
        [String]$Path,

        [parameter(HelpMessage = "Remove all program data for Containerd")]
        [Switch] $Purge
    )

    if (Test-EmptyDirectory -Path "$Path") {
        Write-Error "nerdctl does not exist at '$Path' or the directory is empty."
        return
    }

    # Remove the folder where nerdctl is installed and related folders
    Remove-Item -Path "$Path" -Recurse -Force

    if ($Purge) {
        Write-Output "Purging nerdctl program data"

        # Remove ProgramData files
        Write-Warning "Removing nerdctl program data"
        Uninstall-ProgramFiles "$ENV:ProgramData\nerdctl"

        # Remove from env path
        Write-Warning "Removing nerdctl from env path"
        Remove-FeatureFromPath -Feature "nerdctl"
    }

    Write-Output "Successfully uninstalled nerdctl."
}

Export-ModuleMember -Function Get-NerdctlLatestVersion
Export-ModuleMember -Function Install-Nerdctl
Export-ModuleMember -Function Uninstall-Nerdctl
Export-ModuleMember -Function Uninstall-NerdctlHelper
Export-ModuleMember -Function Install-NerdctlDependencies
