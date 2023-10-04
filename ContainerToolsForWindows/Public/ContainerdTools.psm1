$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\SetupUtilities.psm1"

function Install-Containerd {
    param(
        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "ContainerD version to use. Default 1.7.6")]
        $Version = "1.7.6",

        [String]
        [parameter(HelpMessage = "Path to install containerd. Defaults to ~\program files\containerd")]
        $InstallPath = "$Env:ProgramFiles\containerd",
        
        [String]
        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        $DownloadPath = "$HOME\Downloads"
    )

    $Version = $Version.TrimStart('v')
    $EnvPath = "$InstallPath\bin"
    
    $containerdTarFile = "containerd-${version}-windows-amd64.tar.gz"
    $Uri = "https://github.com/containerd/containerd/releases/download/v$version/$($containerdTarFile)"
    $params = @{
        Feature      = "containerd"
        Version      = $Version
        Uri          = $Uri
        InstallPath  = $InstallPath
        DownloadPath = "$DownloadPath\$containerdTarFile"
        EnvPath      = $EnvPath
        cleanup      = $true
    }

    Write-Output "Downloading and installing Containerd at $InstallPath"
    Invoke-WebRequest -Uri $Uri -OutFile $DownloadPath\$containerdTarFile -Verbose
    Install-RequiredFeature @params

    Write-Output "Containerd successfully installed at $InstallPath"
    containerd.exe -v

    Write-Output "For containerd usage: run 'containerd -h'"
}

function Start-ContainerdService {
    Set-Service containerd -StartupType Automatic
    try {
        Start-Service containerd -Force

        # Waiting for containerd to come to steady state
        (Get-Service containerd -ErrorAction SilentlyContinue).WaitForStatus('Running', '00:00:30')
    }
    catch {
        Throw "Couldn't start Containerd service. $_"
    } 
}

function Stop-ContainerdService {
    try {
        Stop-Service containerd -NoWait -Force

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
        $ContainerdPath = "$Env:ProgramFiles\containerd"
    )

    Write-Output "Configuring the containerd service"

    #Configure containerd service
    $containerdConfigFile = "$ContainerdPath\config.toml"
    $containerdDefault = containerd.exe config default
    $containerdDefault | Out-File $ContainerdPath\config.toml -Encoding ascii
    Write-Information -InformationAction Continue -MessageData "Review containerd configutations at $containerdConfigFile"

    Add-MpPreference -ExclusionProcess "$ContainerdPath\containerd.exe"

    # Review the configuration. Depending on setup you may want to adjust:
    # - the sandbox_image (Kubernetes pause image)
    # - cni bin_dir and conf_dir locations
    # Get-Content $containerdConfigFile

    # Register containerd service
    Add-FeatureToPath -Feature "containerd" -Path "$ContainerdPath\bin"
    containerd.exe --register-service --log-level debug --service-name containerd --log-file "$env:TEMP\containerd.log"
    if ($LASTEXITCODE -gt 0) {
        Throw "Failed to register containerd service. $_"
    }

    Write-Output "Containerd service"
    Get-Service *containerd* | Select-Object Name, DisplayName, ServiceName, ServiceType, StartupType, Status, RequiredServices, ServicesDependedOn
}

function Uninstall-Containerd {
    param(
        [string]
        [parameter(HelpMessage = "Containerd path")]
        $ContainerdPath = "$Env:ProgramFiles\containerd"
    )

    Write-Output "Stopping and uninstalling containerd"
    Stop-ContainerdService

    # Unregister containerd service
    Add-FeatureToPath -Feature "containerd" -Path "$ContainerdPath\bin"
    containerd.exe --unregister-service
    if ($LASTEXITCODE -gt 0) {
        Throw "Could not unregister containerd service. $_"
    }

    # Delete containerd service
    sc.exe delete containerd
    if ($LASTEXITCODE -gt 0) {
        Throw "Could not delete containerd service. $_"
    }

    # Delete the containerd key
    $regkey = "HKLM:\SYSTEM\CurrentControlSet\Services\containerd"
    Get-Item -path $regkey -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -Verbose

    # Remove the folder where containerd service was installed
    Get-Item -Path $ContainerdPath -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    # Remove from env path
    Remove-FeatureFromPath -Feature "containerd"
}

Export-ModuleMember -Function Install-Containerd
Export-ModuleMember -Function Start-ContainerdService -Alias Start-Containerd
Export-ModuleMember -Function Stop-ContainerdService -Alias Stop-Containerd
Export-ModuleMember -Function Initialize-ContainerdService
Export-ModuleMember -Function Uninstall-Containerd
