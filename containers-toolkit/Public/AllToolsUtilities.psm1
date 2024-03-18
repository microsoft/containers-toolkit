###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force


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

    $registerCommands = (Get-Command -Name "*-*Service" | Where-Object { $_.Source -eq 'Containers-Toolkit' }).Name -join ', '
    $message = "For unregistered services/daemons, check the tool's help or register the service using `n`t$registerCommands"
    Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
    return $installedTools
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
        [PSCustomObject]@{
            Feature      = "Containerd"
            Uri          = "https://github.com/containerd/containerd/releases/download/v$containerdVersion/$containerdTarFile"
            Version      = $containerdVersion
            DownloadPath = "$DownloadPath\$($containerdTarFile)"
            InstallPath  = $ContainerdPath
            EnvPath      = "$ContainerdPath\bin"
        }
        [PSCustomObject]@{
            Feature      = "BuildKit"
            Uri          = "https://github.com/moby/buildkit/releases/download/v${BuildKitVersion}/$BuildKitTarFile"
            Version      = $BuildKitVersion
            DownloadPath = "$DownloadPath\$($BuildKitTarFile)"
            InstallPath  = $BuildkitPath
            EnvPath      = "$BuildkitPath\bin"
        }
        [PSCustomObject]@{
            Feature      = "Nerdctl"
            Uri          = "https://github.com/containerd/nerdctl/releases/download/v${nerdctlVersion}/$nerdctlTarFile"
            Version      = $nerdctlVersion
            DownloadPath = "$DownloadPath\$($nerdctlTarFile)"
            InstallPath  = $NerdCTLPath
            EnvPath      = $NerdCTLPath
        }
    )

    # Download files
    Get-InstallationFiles -Files $files

    # Install tools
    foreach ($params in $files) {
        try {
            # Uninstall if tool exists at specified location. Requires user consent
            Uninstall-ContainerTool -Tool $params.Feature -Path $params.InstallPath

            # Untar downloaded files to the specified installation path
            $InstallParams = @{
                Feature      = $params.Feature
                InstallPath  = $params.InstallPath
                DownloadPath = $params.DownloadPath
                EnvPath      = $params.EnvPath
            }
            Install-RequiredFeature @InstallParams -Cleanup $CleanUp
        }
        catch {
            Write-Error "Installation failed for $($params.feature). $_"
        }
    }
}

function Uninstall-ContainerTool($Tool, $Path) {
    $command = "Uninstall-$($Tool) -Path '$Path'"
    Invoke-Expression -Command $command
}

function Get-InstalledVersion($feature, $Latest) {
    $executable = $null
    $daemon = $null
    switch ($feature) {
        "buildkit" {
            $bktdExecutable = (Get-Command "build*.exe" | Where-Object { $_.Source -like "*buildkit*" }) | Select-Object Name
            $executable = ($bktdExecutable[0]).Name

            if ($bktdExecutable.Name.Contains('buildkitd')) {
                $daemon = 'buildkitd'
            }
        }
        Default {
            $executable = (Get-Command "$feature.exe" -ErrorAction Ignore).Name

            if ($feature -eq 'containerd') {
                $daemon = 'containerd'
            }
        }
    }

    $result = [PSCustomObject]@{
        Tool      = $feature
        Installed = $False
    }
    if ($executable) {
        $result = getToolVersion -Executable $executable
        Add-Member -InputObject $result -Name 'Tool' -Value $feature -MemberType 'NoteProperty'
        Add-Member -InputObject $result -Name 'Daemon' -Value $daemon -MemberType 'NoteProperty'

        if ($daemon) {
            Add-Member -InputObject $result -Name 'DaemonStatus' -MemberType 'NoteProperty' `
                -Value (getDaemonStatus -Daemon $daemon)
        }
        $result = $result | Select-Object Tool, Installed, Version, Daemon, @{l = "Daemon Status"; e = { $_.DaemonStatus } }
    }

    # Get latest version
    $latestVersion = "-"
    if ($Latest) {
        $latestVersionCommand = "Get-$($feature)LatestVersion"
        $latestVersion = Invoke-Expression -Command $latestVersionCommand
        Add-Member -InputObject $result -Name 'LatestVersion' -Value "v$latestVersion" -MemberType 'NoteProperty'
        $result = $result | Select-Object Tool, Installed, Version, LatestVersion, Daemon, @{l = "Daemon Status"; e = { $_.DaemonStatus } }
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
        $executablePath = Get-Command $executable.Source -ErrorAction Ignore
        $installed = ($null -ne $executablePath)
    }

    $result = [PSCustomObject]@{
        Installed = $Installed
        Version   = $installedVersion
    }
    return $result
}

function getDaemonStatus($daemon) {
    $daemonStatus = Get-Service -Name $daemon -ErrorAction Ignore
    if ($null -eq $daemonStatus) {
        return 'Unregistered'
    }

    return $daemonStatus.Status
}

Export-ModuleMember -Function Show-ContainerTools
Export-ModuleMember -Function Install-ContainerTools
Export-ModuleMember -Function Uninstall-ContainerTool
