###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force

function Get-ContainerdLatestVersion {
    $latestVersion = Get-LatestToolVersion -Repository "containerd/containerd"
    return $latestVersion
}

function Install-Containerd {
    param(
        [parameter(HelpMessage = "ContainerD version to use. Defaults to latest version")]
        [string]$Version,

        [parameter(HelpMessage = "Path to install containerd. Defaults to ~\program files\containerd")]
        [string]$InstallPath = "$Env:ProgramFiles\Containerd",

        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        [string]$DownloadPath = "$HOME\Downloads",

        [Parameter(HelpMessage = "Register and start Containerd Service")]
        [switch] $Setup
    )

    if (!(Test-EmptyDirectory -Path $InstallPath)) {
        Write-Warning "Containerd already exists at $InstallPath or the directory is not empty"
    }

    # Uninstall if tool exists at specified location. Requires user consent
    try {
        Uninstall-Containerd -Path $InstallPath | Out-Null
    }
    catch {
        Throw "Containerd installation cancelled. $_"
    }

    if (!$Version) {
        # Get default version
        $Version = Get-ContainerdLatestVersion
    }
    $Version = $Version.TrimStart('v')
    Write-Output "Downloading and installing Containerd v$version at $InstallPath"

    $containerdTarFile = "containerd-${version}-windows-amd64.tar.gz"
    $DownloadPath = "$DownloadPath\$($containerdTarFile)"

    # Download files
    $DownloadParams = @(
        @{
            Feature      = "Containerd"
            Uri          = "https://github.com/containerd/containerd/releases/download/v$version/$($containerdTarFile)"
            Version      = $version
            DownloadPath = $DownloadPath
        }
    )
    Get-InstallationFiles -Files $DownloadParams

    # Untar and install tool
    $params = @{
        Feature      = "containerd"
        InstallPath  = $InstallPath
        DownloadPath = $DownloadPath
        EnvPath      = "$InstallPath\bin"
        cleanup      = $true
    }
    Install-RequiredFeature @params

    Write-Output "Containerd v$version successfully installed at $InstallPath `n"

    $showCommands = $true
    try {
        if ($Setup) {
            Register-ContainerdService -ContainerdPath $InstallPath -Start
            Start-ContainerdService
            $showCommands = $false
        }
    }
    catch {
        Write-Warning "Failed to setup Containerd service. $_"
    }

    if ($showCommands) {
        $commands = (Get-command -Name '*containerd*' | Where-Object { $_.Source -like 'Containers-Toolkit' -and $_.Name -ne 'Install-Containerd' }).Name
        $message = "Other useful Containerd commands: $($commands -join ', ').`nTo learn more about each command, run Get-Help <command-name>, e.g., 'Get-Help Register-ContainerdService'"
        Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
    }

    Write-Host "For containerd usage: run 'containerd -h'" -ForegroundColor DarkGreen
}

# YAGNI: Is this necessary?
function Build-ContainerdFromSource {
    Throw "Method or operation not implemented."
}

function Start-ContainerdService {
    Invoke-ServiceAction -Service 'Containerd' -Action 'Start'
}

function Stop-ContainerdService {
    Invoke-ServiceAction -Service 'Containerd' -Action 'Stop'
}

function Register-ContainerdService {
    param(
        [parameter(HelpMessage = "Containerd path")]
        [String]$ContainerdPath,

        [parameter(HelpMessage = "Specify to start Containerd service after registration is complete")]
        [Switch]$Start
    )

    Write-Output "Configuring containerd service"
    if (!$ContainerdPath) {
        $ContainerdPath = Get-DefaultInstallPath -Tool "containerd"
    }

    if (Test-EmptyDirectory -Path $ContainerdPath) {
        Throw "Containerd does not exist at $ContainerdPath or the directory is empty"
    }

    $containerdExecutable = "$ContainerdPath\bin\containerd.exe"
    Add-MpPreference -ExclusionProcess $containerdExecutable

    #Configure containerd service
    $containerdConfigFile = "$ContainerdPath\config.toml"
    Invoke-Expression -Command "& '$containerdExecutable' config default" | Out-File $containerdConfigFile -Encoding ascii
    Write-Information -InformationAction Continue -MessageData "Review containerd configutations at $containerdConfigFile"

    # Register containerd service
    $output = Invoke-ExecutableCommand -Executable $containerdExecutable -Arguments "--register-service --log-level debug --service-name containerd --log-file `"$env:TEMP\containerd.log`""
    if ($output.ExitCode -ne 0) {
        Throw "Failed to register containerd service. $($output.StandardError.ReadToEnd())"
    }

    $containerdService = Get-Service -Name containerd -ErrorAction SilentlyContinue
    if ($null -eq $containerdService ) {
        Throw "Failed to register containerd service. $($Error[0].Exception.Message)"
    }

    Set-Service containerd -StartupType Automatic
    Write-Output "Successfully registered Containerd service."

    if ($Start) {
        Start-ContainerdService
        Write-Output "Successfully started Containerd service."
    }
    else {
        Write-Information -InformationAction Continue -MessageData "To start containerd service, run 'Start-Service containerd' or 'Start-ContainerdService'"
    }
}

function Uninstall-Containerd {
    param(
        [parameter(HelpMessage = "Containerd path")]
        [String]$Path
    )

    $tool = 'Containerd'
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
            Uninstall-ContainerdHelper -Path $path
        }
        catch {
            Throw "Could not uninstall $tool. $_"
        }
    }
    else {
        Throw "$tool uninstallation cancelled."
    }
}

function Uninstall-ContainerdHelper {
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory = $true, HelpMessage = "Containerd path")]
        [String]$Path
    )

    if (Test-EmptyDirectory -Path $Path) {
        Write-Error "Containerd does not exist at $Path or the directory is empty."
        return
    }

    try {
        if (Test-ServiceRegistered -Service 'containerd') {
            Stop-ContainerdService
            Unregister-Containerd -ContainerdPath $Path
        }
    }
    catch {
        Throw "Could not stop or unregister containerd service. $_"
    }

    # Delete the containerd key
    Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\containerd" -Recurse -Force -ErrorAction Ignore

    # Remove the folder where containerd is installed and related folders
    Remove-Item -Path $Path -Recurse -Force

    # FIXME: Access to the path denied
    Remove-Item -Path "$ENV:ProgramData\Containerd" -Recurse -Force -ErrorAction Ignore

    # Remove from env path
    Remove-FeatureFromPath -Feature "containerd"

    Write-Output "Successfully uninstalled Containerd."
}

function Unregister-Containerd ($containerdPath) {
    if (!(Test-ServiceRegistered -Service 'Containerd')) {
        Write-Warning "Containerd service does not exist as an installed service."
        return
    }

    # Unregister containerd service
    $containerdExecutable = "$ContainerdPath\bin\containerd.exe"
    $output = Invoke-ExecutableCommand -Executable $containerdExecutable -Arguments "--unregister-service"
    if ($output.ExitCode -ne 0) {
        Throw "Could not unregister containerd service. $($output.StandardError.ReadToEnd())"
    }
    else {
        Start-Sleep -Seconds 15
    }
}


Export-ModuleMember -Function Get-ContainerdLatestVersion
Export-ModuleMember -Function Install-Containerd
Export-ModuleMember -Function Start-ContainerdService -Alias Start-Containerd
Export-ModuleMember -Function Stop-ContainerdService -Alias Stop-Containerd
Export-ModuleMember -Function Register-ContainerdService
Export-ModuleMember -Function Uninstall-Containerd, Uninstall-ContainerdHelper
