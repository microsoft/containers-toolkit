###########################################################################
#                                                                         #
#   Module Name: BuildkitTools.psm1                                       #
#                                                                         #
#   Description: Wrappers for BuildKit setup functions.                   #
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
###########################################################################

# Reference: https://gist.github.com/gabriel-samfira/6e56238ad11c24f490ac109bdd378471

$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\SetupUtilities.psm1" -Force

function Get-BuildkitLatestVersion {
    $latestVersion = Get-LatestToolVersion -Repository "moby/buildkit"
    return $latestVersion
}

function Install-Buildkit {
    param(
        [parameter(HelpMessage = "Buildkit version to use. Defaults to latest version")]
        [string]$Version = $latestVersion,

        [parameter(HelpMessage = "Path to install buildkit. Defaults to ~\program files\buildkit")]
        [string]$InstallPath = "$Env:ProgramFiles\buildkit",
        
        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        [string]$DownloadPath = "$HOME\Downloads"
    )

    # Uninstall if tool exists at specified location. Requires user consent
    Uninstall-ContainerTool -Tool "Buildkit" -Path $InstallPath

    if (!$Version) {
        $Version = Get-BuildkitLatestVersion
    }
    $Version = $Version.TrimStart('v')

    Write-Output "Downloading and installing Buildkit v$Version at $InstallPath"

    # Download file from repo
    $buildkitTarFile = "buildkit-v${Version}.windows-amd64.tar.gz"
    try {
        $Uri = "https://github.com/moby/buildkit/releases/download/v${Version}/$($BuildKitTarFile)"
        Invoke-WebRequest -Uri $Uri -OutFile $DownloadPath\$buildkitTarFile -Verbose
    }
    catch {
        if ($_.ErrorDetails.Message -eq "Not found") {
            Throw "Buildkit download failed. Invalid URL: $uri"
        }

        Throw "Buildkit download failed. $_"
    }

    $params = @{
        Feature      = "buildkit"
        InstallPath  = $InstallPath
        DownloadPath = "$DownloadPath\$buildkitTarFile"
        EnvPath      = "$InstallPath\bin"
        cleanup      = $true
    }
    Install-RequiredFeature @params

    Write-Output "Successfully installed Buildkit v$Version at $InstallPath"

    Get-ChildItem -Path "C:\Program Files\buildkit\bin" | ForEach-Object {
        $message = Write-Output "For buildctl usage: run '$($_.Name) -h'"
        Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
    }
}

# YAGNI: Is this necessary?
function Build-BuildkitFromSource {
    Throw "Method or operation not implemented."
}

function Start-BuildkitdService {
    Set-Service buildkit -StartupType Automatic
    try {
        Start-Service buildkit -Force

        # Waiting for buildkit to come to steady state
        (Get-Service buildkit -ErrorAction SilentlyContinue).WaitForStatus('Running', '00:00:30')
    }
    catch {
        Write-Error "Couldn't start Buildkit service. $_"
    } 
}

function Stop-BuildkitdService {
    $buildkitStatus = Get-Service buildkit -ErrorAction SilentlyContinue
    if (!$buildkitStatus) {
        Write-Warning "Buildkit service does not exist as an installed service."
        return
    }

    try {
        Stop-Service buildkit -NoWait -Force

        # Waiting for buildkit to come to steady state
        (Get-Service buildkit -ErrorAction SilentlyContinue).WaitForStatus('Stopped', '00:00:30')
    }
    catch {
        Throw "Couldn't stop Buildkit service. $_"
    } 
}

function Initialize-BuildkitdService {
    param(
        [parameter(HelpMessage = "Windows CNI plugin path")]
        [String]$WinCNIPath, 

        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Buildkit path")]
        [String]$BuildKitPath
    )
    if (!$BuildKitPath) {
        $BuildKitPath = Get-DefaultInstallPath -Tool "Buildkit"
    }

    $pathItems = Get-ChildItem -Path $BuildKitPath -ErrorAction SilentlyContinue
    if (!$pathItems.Name.Length) {
        Throw "Buildkit does not exist at $BuildKitPath or the directory is empty"
    }
    
    Add-MpPreference -ExclusionProcess "$BuildkitPath\buildctl.exe"

    # If buildkitd is not installed, terminate execution
    if (!(CheckBuildkitdExists -BuildkitPath $BuildkitPath)) {
        Write-Warning "Buildkitd executable not installed."
        return
    }

    Write-Output "Configuring the buildkit service"
    Add-MpPreference -ExclusionProcess "$BuildkitPath\buildkitd.exe"

    if (!$WinCNIPath) {
        $containerdPath = Get-DefaultInstallPath -Tool "containerd"
        $WinCNIPath = "$containerdPath\cni"
    }

    $cniBinDir = "$WinCNIPath\bin"
    $cniConfPath = "$WinCNIPath\conf\0-containerd-nat.conf"

    # Register buildkit service
    $command = "buildkitd.exe --register-service --debug --containerd-worker=true --containerd-cni-config-path=`"$cniConfPath`" --containerd-cni-binary-dir=`"$cniBinDir`" --service-name buildkitd"
    if (!(Test-Path -Path $cniConfPath)) {
        $consent = Get-ConsentToRegisterBuildkit -Path $cniConfPath

        switch ([ActionConsent]$consent) {
            [ActionConsent]::Yes { 
                Write-Warning "Containerd conf file not found at $cniConfPath. Buildkit service will be registered without Containerd cni configurations."
                $command = "buildkitd.exe --register-service --debug --containerd-worker=true  --service-name buildkitd"
            }
            Default {
                Write-Warning "Failed to register buildkit service. Containerd conf file not found at $cniConfPath. Create the file to resolve this issue, then run this command $command"
                return
            }
        } 
    }
    
    Invoke-Expression -Command $command
    if ($LASTEXITCODE -gt 0) {
        Write-Error "Failed to register buildkitd service."
    }

    sc.exe config buildkitd depend=containerd
    if ($LASTEXITCODE -gt 0) {
        Write-Error "Failed to set dependency for buildkitd on containerd."
    }

    Get-Service *buildkitd* | Select-Object Name, DisplayName, ServiceName, ServiceType, StartupType, Status, RequiredServices, ServicesDependedOn

    sc.exe query buildkitd

    Write-Output "Successfully registered Buildkitd service."
    Write-Information -InformationAction Continue -MessageData "To start buildkitd service, run 'Start-Service buildkitd' or 'Start-BuildkitdService'"

    # YAGNI: Do we need a buildkitd.toml on Windows?
}

function Uninstall-Buildkit {
    param(
        [parameter(HelpMessage = "Buildkit path")]
        [String] $Path
    )
    
    Write-Output "Uninstalling buildkit"
    if (!$path) {
        $path = Get-DefaultInstallPath -Tool "Buildkit"
    }

    $pathItems = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
    if (!$pathItems.Name.Length) {
        Write-Warning "Buildkit does not exist at $Path or the directory is empty"
        return
    }

    try {
        Stop-BuildkitdService
    }
    catch {
        Write-Warning "$_"
    }

    # Unregister buildkit service
    Unregister-Buildkitd

    # Delete the buildkit key
    $regkey = "HKLM:\SYSTEM\CurrentControlSet\Services\buildkit"
    Get-Item -path $regkey -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -Verbose

    # Remove the folder where buildkit service was installed
    Get-Item -Path $Path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    # Remove from env path
    Remove-FeatureFromPath -Feature "buildkit"

    Write-Output "Successfully uninstalled buildkit."
}

function Get-ConsentToRegisterBuildkit ($path) {
    $retry = 2
    $consent = [ActionConsent]::No
    do {
        $title = "Buildkit conf file not found at $path."
        $question = "Do you want to register buildkit service without containerd cni configuration?"
        $choices = '&Yes', '&No'
        $consent = $Host.UI.PromptForChoice($title, $question, $choices, 0)

        $retry -- 
        
    } while (($retry -gt 0 ) -and ($consent -eq [ActionConsent]::No))

    return $consent
}

function CheckBuildkitdExists($buildkitPath) {
    $cmdRes = Get-Command -Name "buildkitd.exe" -ErrorAction SilentlyContinue
    $pathExists = Test-Path -Path "$BuildkitPath\buildkitd.exe"

    return ($cmdRes -or $pathExists)
}

function Unregister-Buildkitd {
    $scQueryResult = (sc.exe query buildkitd) | Select-String -Pattern "SERVICE_NAME: buildkitd"
    if (!$scQueryResult) {
        Write-Warning "Containerd service does not exist as an installed service."
        return
    }
    # Unregister buildkit service
    buildkitd.exe --unregister-service
    if ($LASTEXITCODE -gt 0) {
        Throw "Could not unregister buildkitd service. $_"
    }
    else {
        Start-Sleep -Seconds 15
    }

    # # Delete buildkit service
    # sc.exe delete buildkit
    # if ($LASTEXITCODE -gt 0) {
    #     Throw "Could not delete buildkitd service. $_"
    # }
}


Export-ModuleMember -Function Get-BuildkitLatestVersion
Export-ModuleMember -Function Install-Buildkit
Export-ModuleMember -Function Start-BuildkitdService -Alias Start-Buildkitd
Export-ModuleMember -Function Stop-BuildkitdService -Alias Stop-Buildkitd
Export-ModuleMember -Function Initialize-BuildkitdService 
Export-ModuleMember -Function Uninstall-Buildkit
