$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\SetupUtilities.psm1" -Force

function Get-ContainerdLatestVersion {
    $latestVersion = Get-LatestToolVersion -Repository "containerd/containerd"
    return $latestVersion
}

function Install-Containerd {
    param(
        [parameter(HelpMessage = "ContainerD version to use. Defaults to latest version")]
        [string]$Version,

        [parameter(HelpMessage = "Path to install containerd. Defaults to ~\program files\containerd")]
        [string]$InstallPath = "$Env:ProgramFiles\containerd",
        
        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        [string]$DownloadPath = "$HOME\Downloads"
    )

    # Uninstall if tool exists at specified location. Requires user consent
    Uninstall-ContainerTool -Tool "ContainerD" -Path $InstallPath

    if (!$Version) {
        # Get default version
        $Version = Get-ContainerdLatestVersion
    }
    $Version = $Version.TrimStart('v')
    Write-Output "Downloading and installing Containerd v$version at $InstallPath"
    
    # Download file from repo
    $containerdTarFile = "containerd-${version}-windows-amd64.tar.gz"
    try {
        $Uri = "https://github.com/containerd/containerd/releases/download/v$version/$($containerdTarFile)"
        Invoke-WebRequest -Uri $Uri -OutFile "$DownloadPath\$containerdTarFile" -Verbose
    }
    catch {
        if ($_.ErrorDetails.Message -eq "Not found") {
            Throw "Buildkit download failed. Invalid URL: $uri"
        }

        Throw "Buildkit download failed. $_"
    }

    # Untar and install tool
    $params = @{
        Feature      = "containerd"
        InstallPath  = $InstallPath
        DownloadPath = "$DownloadPath\$containerdTarFile"
        EnvPath      = "$InstallPath\bin"
        cleanup      = $true
    }
    Install-RequiredFeature @params

    Write-Output "Containerd v$version successfully installed at $InstallPath"
    containerd.exe -v

    Write-Output "For containerd usage: run 'containerd -h'"
}

# YAGNI: Is this necessary?
function Build-ContainerdFromSource {
    Throw "Method or operation not implemented."
}

function Start-ContainerdService {
    Set-Service containerd -StartupType Automatic
    try {
        Start-Service containerd

        # Waiting for containerd to come to steady state
        (Get-Service containerd -ErrorAction SilentlyContinue).WaitForStatus('Running', '00:00:30')
    }
    catch {
        Throw "Couldn't start Containerd service. $_"
    } 
}

function Stop-ContainerdService {
    $containerdStatus = Get-Service containerd -ErrorAction SilentlyContinue
    if (!$containerdStatus) {
        Write-Warning "Containerd service does not exist as an installed service."
        return
    }

    try {
        Stop-Service containerd -NoWait

        # Waiting for containerd to come to steady state
        (Get-Service containerd -ErrorAction SilentlyContinue).WaitForStatus('Stopped', '00:00:30')
    }
    catch {
        Throw "Couldn't stop Containerd service. $_"
    } 
}

function Initialize-ContainerdService {
    param(
        [string]
        [parameter(HelpMessage = "Containerd path")]
        $ContainerdPath
    )

    Write-Output "Configuring the containerd service"
    if (!$ContainerdPath) {
        $ContainerdPath = Get-DefaultInstallPath -Tool "containerd"
    }

    $pathItems = Get-ChildItem -Path $ContainerdPath -ErrorAction SilentlyContinue
    if (!$pathItems.Name.Length) {
        Throw "Containerd does not exist at $ContainerdPath or the directory is empty"
    }

    #Configure containerd service
    $containerdConfigFile = "$ContainerdPath\config.toml"
    $containerdDefault = containerd.exe config default
    $containerdDefault | Out-File "$ContainerdPath\config.toml" -Encoding ascii
    Write-Information -InformationAction Continue -MessageData "Review containerd configutations at $containerdConfigFile"

    Add-MpPreference -ExclusionProcess "$ContainerdPath\containerd.exe"

    # Review the configuration. Depending on setup you may want to adjust:
    # - the sandbox_image (Kubernetes pause image)
    # - cni bin_dir and conf_dir locations
    # Get-Content $containerdConfigFile

    # Register containerd service
    containerd.exe --register-service --log-level debug --service-name containerd --log-file "$env:TEMP\containerd.log"
    if ($LASTEXITCODE -gt 0) {
        Throw "Failed to register containerd service. $_"
    }

    Get-Service *containerd* | Select-Object Name, DisplayName, ServiceName, ServiceType, StartupType, Status, RequiredServices, ServicesDependedOn

    sc.exe query containerd

    Write-Output "Successfully registered Containerd service."
    Write-Information -InformationAction Continue -MessageData "To start containerd service, run 'Start-Service containerd' or 'Start-ContainerdService'"
}

function Uninstall-Containerd {
    param(
        [string]
        [parameter(HelpMessage = "Containerd path")]
        $Path
    )
    Write-Output "Uninstalling containerd"

    if (!$Path) {
        $Path = Get-DefaultInstallPath -Tool "containerd"
    }

    $pathItems = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
    if (!$pathItems.Name.Length) {
        Write-Warning "Containerd does not exist at $Path or the directory is empty"
        return
    }

    try {
        Stop-ContainerdService
    }
    catch {
        Write-Warning "$_"
    }

    # Unregister containerd service
    Unregister-Containerd

    # Delete the containerd key
    $regkey = "HKLM:\SYSTEM\CurrentControlSet\Services\containerd"
    Get-Item -path $regkey -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    # Remove the folder where containerd service was installed
    Get-Item -Path $Path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    # Remove from env path
    Remove-FeatureFromPath -Feature "containerd"

    Write-Output "Successfully uninstalled Containerd."
}
function Unregister-Containerd {
    $scQueryResult = (sc.exe query containerd) | Select-String -Pattern "SERVICE_NAME: containerd"
    if (!$scQueryResult) {
        Write-Warning "Containerd service does not exist as an installed service."
        return
    }
    # Unregister containerd service
    containerd.exe --unregister-service
    if ($LASTEXITCODE -gt 0) {
        Write-Warning "Could not unregister containerd service. $_"
    }
    else {
        Start-Sleep -Seconds 15
    }
    
    # # Delete containerd service
    # sc.exe delete containerd
    # if ($LASTEXITCODE -gt 0) {
    #     Write-Warning "Could not delete containerd service. $_"
    # }
}


Export-ModuleMember -Function Get-ContainerdLatestVersion
Export-ModuleMember -Function Install-Containerd
Export-ModuleMember -Function Start-ContainerdService -Alias Start-Containerd
Export-ModuleMember -Function Stop-ContainerdService -Alias Stop-Containerd
Export-ModuleMember -Function Initialize-ContainerdService
Export-ModuleMember -Function Uninstall-Containerd
