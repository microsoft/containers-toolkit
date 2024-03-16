###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force

function Get-BuildkitLatestVersion {
    $latestVersion = Get-LatestToolVersion -Repository "moby/buildkit"
    return $latestVersion
}

function Install-Buildkit {
    [CmdletBinding(DefaultParameterSetName = 'Install')]
    param (
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Setup')]
        [parameter(HelpMessage = "Buildkit version to use. Defaults to latest version")]
        [string]$Version,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Setup')]
        [parameter(HelpMessage = "Path to install buildkit. Defaults to ~\program files\buildkit")]
        [string]$InstallPath = "$Env:ProgramFiles\Buildkit",

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Setup')]
        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        [string]$DownloadPath = "$HOME\Downloads",

        [Parameter(ParameterSetName = 'Setup')]
        [switch]$Setup,

        [Parameter(ParameterSetName = 'Setup')]
        [string]$WinCNIPath
    )

    if (!(Test-EmptyDirectory -Path $InstallPath)) {
        Write-Warning "Buildkit already exists at $InstallPath or the directory is not empty"
    }

    # Uninstall if tool exists at specified location. Requires user consent
    try {
        Uninstall-Buildkit -Path $InstallPath | Out-Null
    }
    catch {
        Throw "Buildkit installation cancelled. $_"
    }

    if (!$Version) {
        $Version = Get-BuildkitLatestVersion
    }
    $Version = $Version.TrimStart('v')

    Write-Output "Downloading and installing Buildkit v$Version at $InstallPath"

    # Download file from repo
    $buildkitTarFile = "buildkit-v${Version}.windows-amd64.tar.gz"
    $DownloadPath = "$DownloadPath\$($buildkitTarFile)"

    # Download files
    $DownloadParams = @(
        @{
            Feature      = "Buildkit"
            Uri          = "https://github.com/moby/buildkit/releases/download/v${Version}/$($BuildKitTarFile)"
            Version      = $version
            DownloadPath = $DownloadPath
        }
    )
    Get-InstallationFiles -Files $DownloadParams

    # Untar downloaded file at install path
    $params = @{
        Feature      = "Buildkit"
        InstallPath  = $InstallPath
        DownloadPath = "$DownloadPath"
        EnvPath      = "$InstallPath\bin"
        cleanup      = $true
    }
    Install-RequiredFeature @params

    Write-Output "Successfully installed Buildkit v$Version at $InstallPath`n"

    # Register Buildkitd service
    $showCommands = $true
    try {
        if ($Setup) {
            Register-BuildkitdService -BuildKitPath $InstallPath -WinCNIPath $WinCNIPath -Start
            Start-BuildkitdService
            $showCommands = $false
        }
    }
    catch {
        Write-Warning "Failed to registed and start Buildkitd service. $_"
    }

    if ($showCommands) {
        $commands = (Get-command -Name '*buildkit*' | Where-Object { $_.Source -like 'Containers-Toolkit' -and $_.Name -ne 'Install-Buildkit' }).Name
        $message = "Other useful Buildkit commands: $($commands -join ', ').`nTo learn more about each command, run Get-Help <command-name>, e.g., 'Get-Help Register-BuildkitdService'`n"
        Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
    }

    # Show buildkit binaries help
    Get-ChildItem -Path "C:\Program Files\buildkit\bin" | ForEach-Object {
        $message = "For buildctl usage: run '$($_.Name) -h'"
        Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
    }
}

# YAGNI: Is this necessary?
function Build-BuildkitFromSource {
    Throw "Method or operation not implemented."
}

function Start-BuildkitdService {
    Invoke-ServiceAction -Service 'Buildkitd' -Action 'Start'
}

function Stop-BuildkitdService {
    Invoke-ServiceAction -Service 'Buildkitd' -Action 'Stop'
}

function Register-BuildkitdService {
    param(
        [parameter(HelpMessage = "Windows CNI plugin path")]
        [String]$WinCNIPath,

        [parameter(HelpMessage = "Buildkit path")]
        [String]$BuildKitPath,

        [parameter(HelpMessage = "Specify to start Buildkitd service after registration is complete")]
        [Switch]$Start
    )
    if (!$BuildKitPath) {
        $BuildKitPath = Get-DefaultInstallPath -Tool "Buildkit"
    }

    if (Test-EmptyDirectory -Path $BuildKitPath) {
        Throw "Buildkit does not exist at $BuildKitPath or the directory is empty"
    }

    # If buildkitd is not installed, terminate execution
    if (!(Test-BuildkitdServiceExists -BuildkitPath $BuildkitPath)) {
        Write-Error "Buildkitd executable not installed."
        return
    }
    Write-Output "Configuring buildkitd service"

    $buildkitdExecutable = "$BuildKitPath\bin\buildkitd.exe"
    Add-MpPreference -ExclusionProcess $buildkitdExecutable

    if (!$WinCNIPath) {
        $containerdPath = Get-DefaultInstallPath -Tool "containerd"
        $WinCNIPath = "$containerdPath\cni"
    }

    $cniBinDir = "$WinCNIPath\bin"
    $cniConfPath = "$WinCNIPath\conf\0-containerd-nat.conf"

    # Register buildkit service
    $command = "buildkitd.exe --register-service --debug --containerd-worker=true --containerd-cni-config-path=`"$cniConfPath`" --containerd-cni-binary-dir=`"$cniBinDir`" --service-name buildkitd"
    if (Test-ConfFileEmpty -Path $cniConfPath) {
        $consent = Get-ConsentToRegisterBuildkit -Path $cniConfPath

        switch ([ActionConsent]$consent) {
            ([ActionConsent]::Yes) {
                Write-Warning "Containerd conf file not found at $cniConfPath. Buildkit service will be registered without Containerd cni configurations."
                $command = "buildkitd.exe --register-service --debug --containerd-worker=true --service-name buildkitd"
            }
            Default {
                Throw "Failed to register buildkit service. Containerd conf file not found at $cniConfPath. Create the file to resolve this issue, then run this command $command"
            }
        }
    }

    $arguments = ($command -split " " | Select-Object -Skip 1) -join " "
    $output = Invoke-ExecutableCommand -Executable $buildkitdExecutable -Arguments $arguments
    if ($output.ExitCode -ne 0) {
        Throw "Failed to register buildkitd service. $($output.StandardError.ReadToEnd())"
    }

    $buildkitdService = Get-Service buildkitd -ErrorAction SilentlyContinue
    if ($null -eq $buildkitdService ) {
        Throw "Failed to register buildkitd service. $($Error[0].Exception.Message)"
    }

    Set-Service buildkitd -StartupType Automatic
    Write-Output "Successfully registered Buildkitd service.".

    $output = Invoke-ExecutableCommand -Executable 'sc.exe' -arguments 'config buildkitd depend=containerd'
    if ($output.ExitCode -ne 0) {
        Write-Error "Failed to set dependency for buildkitd on containerd. $($output.StandardOutput.ReadToEnd())"
    }

    if ($Start) {
        Start-BuildkitdService
        Write-Output "Successfully started Buildkitd service."
    }
    else {
        Write-Information -InformationAction Continue -MessageData "To start buildkitd service, run 'Start-Service buildkitd' or 'Start-BuildkitdService'"
    }

    # YAGNI: Do we need a buildkitd.toml on Windows?
}

function Uninstall-Buildkit {
    param(
        [parameter(HelpMessage = "Buildkit path")]
        [String]$Path
    )

    $tool = 'Buildkit'
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
            Uninstall-BuildkitHelper -Path $path
        }
        catch {
            Throw "Could not uninstall $tool. $_"
        }
    }
    else {
        Throw "$tool uninstallation cancelled."
    }
}

function Uninstall-BuildkitHelper {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Buildkit path")]
        [String]$Path
    )

    if (Test-EmptyDirectory -Path $Path) {
        Write-Error "Buildkit does not exist at $Path or the directory is empty."
        return
    }

    try {
        if (Test-ServiceRegistered -Service 'Buildkitd') {
            Stop-BuildkitdService
            Unregister-Buildkitd
        }
    }
    catch {
        Throw "Could not stop or unregister buildkitd service. $_"
    }

    # Delete the buildkit key
    Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\buildkit" -Recurse -Force -ErrorAction Ignore

    # Remove the folder where buildkit is installed and related folders
    Remove-Item -Path $Path -Recurse -Force

    # FIXME: Access to the path denied
    Remove-Item -Path "$ENV:ProgramData\Buildkit" -Recurse -Force -ErrorAction Ignore

    # Remove from env path
    Remove-FeatureFromPath -Feature "buildkit"

    Write-Output "Successfully uninstalled buildkit."
}

function Test-ConfFileEmpty($Path) {
    if (!(Test-Path -LiteralPath $Path)) {
        return $true
    }

    $isFileNotEmpty = (([System.IO.File]::ReadAllText($Path)) -match '\S')
    return (-not $isFileNotEmpty )
}

function Get-ConsentToRegisterBuildkit ($path) {
    $retry = 2
    $consent = [ActionConsent]::No
    do {
        $title = "Buildkit conf file not found at $path."
        $question = "Do you want to register buildkit service without containerd cni configuration?"
        $choices = '&Yes', '&No'
        $consent = (Get-Host).UI.PromptForChoice($title, $question, $choices, 0)

        $retry --

    } while (($retry -gt 0 ) -and ($consent -eq [ActionConsent]::No))

    return $consent
}

function Test-BuildkitdServiceExists($buildkitPath) {
    $cmdRes = Get-Command -Name "buildkitd.exe" -ErrorAction Ignore
    $pathExists = Test-Path -Path "$BuildkitPath\bin\buildkitd.exe"

    return ($cmdRes -or $pathExists)
}

function Unregister-Buildkitd($buildkitPath) {
    if (!(Test-ServiceRegistered -Service 'buildkitd')) {
        Write-Warning "Buildkitd service does not exist as an installed service."
        return
    }

    # Unregister buildkit service
    $buildkitdExecutable = "$buildkitPath\bin\buildkitd.exe"
    $output = Invoke-ExecutableCommand -Executable $buildkitdExecutable -Arguments "--unregister-service"
    if ($output.ExitCode -ne 0) {
        Throw "Could not unregister buildkitd service. $($output.StandardError.ReadToEnd())"
    }
    else {
        Start-Sleep -Seconds 15
    }
}


Export-ModuleMember -Function Get-BuildkitLatestVersion
Export-ModuleMember -Function Install-Buildkit
Export-ModuleMember -Function Start-BuildkitdService -Alias Start-Buildkitd
Export-ModuleMember -Function Stop-BuildkitdService -Alias Stop-Buildkitd
Export-ModuleMember -Function Register-BuildkitdService -Alias Register-Buildkitd
Export-ModuleMember -Function Uninstall-Buildkit, Uninstall-BuildkitHelper
