$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\SetupUtilities.psm1" -Force


# NEEDSDOC: Update help documentation
function Show-ContainerTools {
    param (
        [Parameter(HelpMessage = "Show latest release version")]
        [Switch]$Latest
    )

    $tools = @("containerd", "buildkit", "nerdctl")
    
    $installedTools = @()
    foreach ($tool in $tools) {
        $command = "Get-InstalledVersion -Feature $tool"
        if ($Latest) {
            $command += " -Latest $true"
        }
        $installedTools += Invoke-Expression -Command $command
    }
    
    Write-Warning "Checks if files are installed in $Env:ProgramFiles and the version using the tools print versions. This information may not be accurate if the tools have been installed in a different location and/or the paths have not been added to environment path."
    return $installedTools
}

function Get-InstalledVersion($feature, $Latest) {
    $executable = $null
    switch ($feature) {
        "buildkit" {
            $bktdExecutable = (Get-Command "build*.exe" | Where-Object { $_.Source -like "*buildkit*" }) | Select-Object Name
            $executable = ($bktdExecutable[0]).Name
        }
        Default {
            $executable = (Get-Command "$feature.exe" ).Name
        }
    }
    
    # Get latest version
    $latestVersion = "-"
    if ($Latest) {
        $latestVersionCommand = "Get-$($feature)LatestVersion"
        $latestVersion = Invoke-Expression -Command $latestVersionCommand
        $latestVersion = "v$latestVersion"
    }
    

    $result = [PSCustomObject]@{
        Tool      = $feature
        Installed = $False
    }
    if ($executable) {
        $result = getToolVersion -Executable $executable
        Add-Member -InputObject $result -Name 'Tool' -Value $feature -MemberType 'NoteProperty'
        $result = $result | Select-Object Tool, Installed, Version
    }

    # Get latest version
    $latestVersion = "-"
    if ($Latest) {
        $latestVersionCommand = "Get-$($feature)LatestVersion"
        $latestVersion = Invoke-Expression -Command $latestVersionCommand
        Add-Member -InputObject $result -Name 'LatestVersion' -Value "v$latestVersion" -MemberType 'NoteProperty'
    }

    return $result
}

function getToolVersion($executable) {
    $installedVersion = $null
    try {
        $version = Invoke-Expression -Command "$executable -v"

        $pattern = "(\d+\.)(\d+\.)(\*|\d+)"
        $installedVersion = ($version | Select-String -Pattern $pattern).Matches.Value
        if ($installedVersion) {
            $installedVersion = "v$installedVersion"
        }
        else {
            $installedVersion = 'unknown'
        }   
    }
    catch {
        $installedVersion = "-"
    }

    $Installed = ($null -ne $installedVersion)
    if (!$Installed) {
        $executablePath = Get-Command $executable.Source
        $installed = ($null -ne $executablePath)      
    }

    $result = [PSCustomObject]@{
        Installed = $Installed
        Version   = $installedVersion
    }
    return $result
}

function Install-ContainerTools {
    param(
        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "ContainerD version to use")]
        $ContainerDVersion = (Get-ContainerdLatestVersion),

        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Buildkit version to use")]
        $BuildKitVersion = (Get-BuildkitLatestVersion),

        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "nerdctl version to use")]
        $NerdCTLVersion = (Get-NerdctlLatestVersion),
        
        [String]
        [parameter(HelpMessage = "Path to Install files. Defaults to Program Files")]
        $InstallPath = $Env:ProgramFiles,

        [String]
        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        $DownloadPath = "$HOME\Downloads",

        [switch]
        [parameter(HelpMessage = "Cleanup after installation is done")]
        $CleanUp
    )

    # Global Variables needed for the script
    $containerdTarFile = "containerd-${containerdVersion}-windows-amd64.tar.gz"
    $BuildKitTarFile = "buildkit-v${BuildKitVersion}.windows-amd64.tar.gz"
    $nerdctlTarFile = "nerdctl-${nerdctlVersion}-windows-amd64.tar.gz"

    # Installation paths
    $ContainerdPath = "$InstallPath\Containerd"
    $BuildkitPath = "$InstallPath\Buildkit"
    $NerdCTLPath = "$InstallPath\Nerdctl"


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
            Feature      = "Nerdctl"
            Uri          = "https://github.com/containerd/nerdctl/releases/download/v${nerdctlVersion}/$($nerdctlTarFile)"
            Version      = $nerdctlVersion
            DownloadPath = "$DownloadPath\$($nerdctlTarFile)"
            InstallPath  = $NerdCTLPath
            EnvPath      = $NerdCTLPath
        }
    )

    # Download files
    Get-InstallationFiles -Files $Files

    foreach ($feature in $files) {
        
        try {
            # Uninstall if tool exists at specified location. Requires user consent
            Uninstall-ContainerTool -Tool $Feature.Feature -Path $feature.InstallPath

            # Untar downloaded files to the specified installation path
            Install-RequiredFeature @feature -Cleanup $CleanUp
        }
        catch {
            Write-Error $_
        }
    }    
}


Export-ModuleMember -Function Show-ContainerTools
Export-ModuleMember -Function Install-ContainerTools 
