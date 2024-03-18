###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force

function Get-NerdctlLatestVersion {
    $latestVersion = Get-LatestToolVersion -Repository "containerd/nerdctl"
    return $latestVersion
}

function Install-Nerdctl {
    param(
        [string]
        [parameter(HelpMessage = "Nerdctl version to use. Defaults to latest version")]
        $Version,

        [String]
        [parameter(HelpMessage = "Path to install nerdctl. Defaults to ~\program files\nerdctl")]
        $InstallPath = "$Env:ProgramFiles\nerdctl",

        [String]
        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        $DownloadPath = "$HOME\Downloads"
    )

    if (!(Test-EmptyDirectory -Path $InstallPath)) {
        Write-Warning "$Nerdctl already exists at $InstallPath or the directory is not empty"
    }

    # Uninstall if tool exists at specified location. Requires user consent
    try {
        Uninstall-Nerdctl -Path $InstallPath | Out-Null
    }
    catch {
        Throw "Nerdctl installation cancelled. $_"
    }

    if (!$Version) {
        $Version = Get-NerdctlLatestVersion
    }
    $Version = $Version.TrimStart('v')
    Write-Output "Downloading and installing Nerdctl v$version at $InstallPath"

    # Download file from repo
    $nerdctlTarFile = "nerdctl-$version-windows-amd64.tar.gz"
    $DownloadPath = "$DownloadPath\$nerdctlTarFile"
    $DownloadParams = @(
        @{
            Feature      = "nerdctl"
            Uri          = "https://github.com/containerd/nerdctl/releases/download/v${version}/$nerdctlTarFile"
            Version      = $version
            DownloadPath = $DownloadPath
        }
    )
    Get-InstallationFiles -Files $DownloadParams

    # Untar and install tool
    $params = @{
        Feature      = "nerdctl"
        InstallPath  = $InstallPath
        DownloadPath = $DownloadPath
        EnvPath      = $InstallPath
        cleanup      = $true
    }
    Install-RequiredFeature @params

    Write-Output "Nerdctl v$version successfully installed at $InstallPath"
    Write-Output "For nerdctl usage: run 'nerdctl -h'"
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
    param(
        [parameter(HelpMessage = "Nerdctl path")]
        [String]$Path
    )
    if (!$Path) {
        $Path = Get-DefaultInstallPath -Tool "nerdctl"
    }

    $tool = 'Nerdctl'
    if (!$Path) {
        $Path = Get-DefaultInstallPath -Tool $tool
    }

    if (Test-EmptyDirectory -Path $path) {
        Write-Output "$tool does not exist at $Path or the directory is empty"
        return
    }

    $consent = Uninstall-ContainerToolConsent -Tool $tool -Path $Path
    if ($consent) {
        Write-Warning "Uninstalling preinstalled $tool at the path $path"
        try {
            Uninstall-NerdctlHelper -Path $path
        }
        catch {
            Throw "Could not uninstall $tool. $_"
        }
    }
    else{
        Throw "$tool uninstallation cancelled."
    }
}

function Uninstall-NerdctlHelper {
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory = $true, HelpMessage = "Nerdctl path")]
        [String]$Path
    )

    if (Test-EmptyDirectory -Path $Path) {
        Write-Error "Nerdctl does not exist at $Path or the directory is empty."
        return
    }

    # Remove the folder where nerdctl is installed and related folders
    Remove-Item -Path $Path -Recurse -Force
    Remove-Item -Path "$ENV:ProgramData\nerdctl" -Recurse -Force -ErrorAction Ignore

    # Remove from env path
    Remove-FeatureFromPath -Feature "nerdctl"

    Write-Output "Successfully uninstalled nerdctl."
}

Export-ModuleMember -Function Get-NerdctlLatestVersion
Export-ModuleMember -Function Install-Nerdctl
Export-ModuleMember -Function Uninstall-Nerdctl
Export-ModuleMember -Function Uninstall-NerdctlHelper
