$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\SetupUtilities.psm1"

function Get-InstallationFiles {
    param(
        [PSCustomObject]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Files to download")]
        $Files
    )
    
    Write-Information -InformationAction Continue -MessageData "Downloading installation files"

    if (!(Get-Module -Name ThreadJob)) {
        Install-Module -Name ThreadJob -Scope CurrentUser
    }

    $jobs = @()
    
    # Create multiple thread jobs to download multiple files at the same time.
    foreach ($file in $files) {
        $jobs += Start-ThreadJob -Name $file.DownloadPath `
            -ScriptBlock {
            $feature = $using:file

            Write-Information -InformationAction Continue -MessageData "Downloading $($feature.Feature) version $($feature.Version)"
            try {
                    
                Invoke-WebRequest -Uri $feature.Uri -OutFile $feature.DownloadPath
            }
            catch {
                Write-Error "Failed for $($feature.feature): $($feature.uri). $_"
                exit
            }
        }
    }

    Wait-Job -Job $jobs

    foreach ($job in $jobs) {
        Receive-Job -Job $job
    }
}

function Install-RequiredFeature {
    param(
        [string] $Feature,
        [string] $Version,
        [string] $Uri,
        [string] $InstallPath,
        [string] $DownloadPath,
        [string] $EnvPath,
        [boolean] $cleanup
    )
     
    if ((Get-ChildItem -Path $InstallPath)) {
        Write-Warning "Uninstalling preinstalled $Feature at the path $InstallPath"
        if ($Feature -match "containerd") {
            try {
                Uninstall-Containerd 
            }
            catch {
                Write-Error $_
            }

            Remove-FeatureFromPath -Feature $feature
        }
        else {
            Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction Continue
        }
        Remove-FeatureFromPath -Feature $feature
    }
    
    # Create the directory to untar to
    Write-Information -InformationAction Continue -MessageData "Extracting $Feature to $InstallPath"
    if (!(Test-Path $InstallPath)) { 
        New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null 
    }

    # Untar file
    tar.exe -xf $DownloadPath -C $InstallPath
    if ($LASTEXITCODE -gt 0) {
        Throw "Couldn't untar $DownloadPath. $_"
    }

    # Add to env path
    Add-FeatureToPath -Feature $Feature -Path $EnvPath

    # Clean up
    if ($CleanUp) {
        Write-Output "Cleanup to remove downloaded files"
        Remove-Item $downloadPath -Force -ErrorAction Continue
    }
}

function Install-ContainerTools {
    param(
        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "ContainerD version to use")]
        $ContainerDVersion = "1.7.6",

        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Buildkit version to use")]
        $BuildKitVersion = "0.12.2",

        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "nerdctl version to use")]
        $NerdCTLVersion = "1.6.0",

        [String]
        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        $DownloadPath,

        [boolean]
        [parameter(HelpMessage = "Cleanup after installation is done")]
        $CleanUp
    )

    # Global Variables needed for the script
    $containerdTarFile = "containerd-${containerdVersion}-windows-amd64.tar.gz"
    $BuildKitTarFile = "buildkit-v${BuildKitVersion}.windows-amd64.tar.gz"
    $cniZipFile = "windows-container-networking-cni-amd64-v${WinCNIVersion}.zip"
    $nerdctlTarFile = "nerdctl-${nerdctlVersion}-windows-amd64.tar.gz"

    # Installation paths
    $ContainerdPath = "$Env:ProgramFiles\Containerd"
    $BuildkitPath = "$Env:ProgramFiles\Buildkit"
    $NerdCTLPath = "$Env:ProgramFiles\Nerdctl"

    if (!$DownloadPath) {
        $DownloadPath = "$HOME\Downloads"
    }

    $files = @(
        @{
            Feature      = "Containerd"
            Uri          = "https://github.com/containerd/containerd/releases/download/v$containerdVersion/$($containerdTarFile)"
            Version      = $containerdVersion
            DownloadPath = "$DownloadPath\$($containerdTarFile)"
            InstallPath  = $ContainerdPath
            EnvPath      = "$ContainerdPath\bin"
        }
        @{
            Feature      = "BuildKit"
            Uri          = "https://github.com/moby/buildkit/releases/download/v${BuildKitVersion}/$($BuildKitTarFile)"
            Version      = $BuildKitVersion
            DownloadPath = "$DownloadPath\$($BuildKitTarFile)"
            InstallPath  = $BuildkitPath
            EnvPath      = "$BuildkitPath\bin"
        }
        @{
            Feature      = "nerdctl"
            Uri          = "https://github.com/containerd/nerdctl/releases/download/v${nerdctlVersion}/$($nerdctlTarFile)"
            Version      = $nerdctlVersion
            DownloadPath = "$DownloadPath\$($nerdctlTarFile)"
            InstallPath  = $NerdCTLPath
            EnvPath      = $NerdCTLPath
        }
    )

    # Download files
    Get-InstallationFiles -DownloadPath $DownloadPath -Files $Files

    foreach ($feature in $files) {
        Install-RequiredFeature @feature -Cleanup $CleanUp
    }    
}


Export-ModuleMember -Function Get-InstallationFiles
Export-ModuleMember -Function Install-RequiredFeature
Export-ModuleMember -Function Install-ContainerTools 
