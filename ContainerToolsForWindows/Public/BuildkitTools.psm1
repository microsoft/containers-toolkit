# Reference: https://gist.github.com/gabriel-samfira/6e56238ad11c24f490ac109bdd378471

$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\SetupUtilities.psm1"

function Start-BuildkitService {
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

function Stop-BuildkitService {
    try {
        Stop-Service buildkit -NoWait -Force

        # Waiting for buildkit to come to steady state
        (Get-Service buildkit -ErrorAction SilentlyContinue).WaitForStatus('Stopped', '00:00:30')
    }
    catch {
        Write-Error "Couldn't stop Buildkit service. $_"
    } 
}

function Initialize-BuildkitService {
    param(
        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Buildkit path")]
        $BuildKitPath = "$Env:ProgramFiles\buildkit",

        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Windows CNI plugin path")]
        $WinCNIPath = "$Env:ProgramFiles\containerd\cni"
    )

    if (!(Test-Path -Path $BuildKitPath)){
        Throw "Buildkit not found at $_"
    }

    Write-Output "Configuring the buildkit service"

    Add-MpPreference -ExclusionProcess "$BuildkitPath\buildkit.exe"

    $cniBinDir = "$WinCNIPath\bin"
    $cniConfPath = "$WinCNIPath\conf\0-containerd-nat.conf"

    # Register buildkit service
    $command = "buildkit.exe --register-service --debug --containerd-worker=true --containerd-cni-config-path=`"$cniConfPath`" --containerd-cni-binary-dir=`"$cniBinDir`" --service-name buildkitd"
    if (!(Test-Path($cniConfPath))) {
        $retry = 0
        while ($retry -lt 2) {
            Write-Warning "Containerd conf file not found at $cniConfPath."
            $consent = Read-Host "Do you want to register buildkit service without containerd cni configuration? [Y|n]: "
            if ($consent -eq "Y") {
                break
            }
            
            $retry ++
        }

        if ($consent -ne "Y") {
            Write-Warning "Failed to register buildkit service. Containerd conf file not found at $cniConfPath. Create the file to resolve this issue, then run this command $command"
            return
        }
        
        Write-Warning "Buildkit service will be registered without a containerd cni configuration."
        $command = "buildkit.exe --debug --containerd-worker=true --register-service  --service-name buildkitd"
    }
    
    Invoke-Expression -Command $command
    if ($LASTEXITCODE -gt 0) {
        Write-Error "Failed to register buildkitd service."
    }

    sc.exe config buildkitd depend=containerd
    if ($LASTEXITCODE -gt 0) {
        Write-Error "Failed to set dependency for buildkitd on containerd."
    }
}

function Uninstall-Buildkit {
    param(
        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Buildkit path")]
        $BuildKitPath = "$Env:ProgramFiles\buildkit"
    )
    
    Write-Output "Stopping and uninstalling buildkit"
    Stop-BuildkitService

    # Unregister buildkit service
    Add-FeatureToPath -Feature "buildkit" -Path "$BuildkitPath\bin"
    buildkit.exe --unregister-service
    if ($LASTEXITCODE -gt 0) {
        Throw "Could not unregister buildkitd service. $_"
    }

    # Delete buildkit service
    sc.exe delete buildkit
    if ($LASTEXITCODE -gt 0) {
        Throw "Could not delete buildkitd service. $_"
    }

    # Delete the buildkit key
    $regkey = "HKLM:\SYSTEM\CurrentControlSet\Services\buildkit"
    Get-Item -path $regkey -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -Verbose

    # Remove the folder where buildkit service was installed
    Get-Item -Path $BuildkitPath -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    # Remove from env path
    Remove-FeatureFromPath -Feature "buildkit"
}

Export-ModuleMember -Function Start-BuildkitService 
Export-ModuleMember -Function Stop-BuildkitService
Export-ModuleMember -Function Initialize-BuildkitService 
Export-ModuleMember -Function Uninstall-Buildkit
