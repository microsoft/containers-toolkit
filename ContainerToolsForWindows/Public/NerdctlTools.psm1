$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\SetupUtilities.psm1" -Force

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

    # Uninstall if tool exists at specified location. Requires user consent
    Uninstall-ContainerTool -Tool "Nerdctl" -Path $InstallPath

    if (!$Version) {
        $Version = Get-NerdctlLatestVersion
    }
    $Version = $Version.TrimStart('v')
    Write-Output "Downloading and installing Nerdctl v$version at $InstallPath"

    # Download file from repo
    $nerdctlTarFile = "nerdctl-$version-windows-amd64.tar.gz"
    try {
        $Uri = "https://github.com/containerd/nerdctl/releases/download/v${version}/$nerdctlTarFile"
        Invoke-WebRequest -Uri $Uri -OutFile $DownloadPath\$nerdctlTarFile -Verbose
    }
    catch {
        if ($_.ErrorDetails.Message -eq "Not found") {
            Throw "Nerdctl download failed. Invalid URL: $uri"
        }

        Throw "Nerdctl download failed. $_"
    }

    # Untar and install tool
    $params = @{
        Feature      = "nerdctl"
        InstallPath  = $InstallPath
        DownloadPath = "$DownloadPath\$nerdctlTarFile"
        EnvPath      = $InstallPath
        cleanup      = $true
    }
    Install-RequiredFeature @params

    Write-Output "Nerdctl v$version successfully installed at $InstallPath"
    nerdctl.exe -v

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
    
    Write-Output "Uninstalling nerdctl"
    $pathItems = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
    if (!$pathItems.Name.Length) {
        Write-Error "Nerdctl does not exist at $Path or the directory is empty"
        return
    }

    # Remove the folder where nerdctl was installed
    Get-Item -Path $Path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    # Remove from env path
    Remove-FeatureFromPath -Feature "nerdctl"

    Write-Output "Successfully uninstalled nerdctl."
}

Export-ModuleMember -Function Get-NerdctlLatestVersion
Export-ModuleMember -Function Install-Nerdctl
Export-ModuleMember -Function Uninstall-Nerdctl
