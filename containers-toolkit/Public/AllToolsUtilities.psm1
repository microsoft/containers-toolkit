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
        $installedTools += (Get-InstalledVersion -Feature $tool -Latest:$Latest)
    }

    $registerCommands = (Get-Command -Name "*-*Service" | Where-Object { $_.Source -eq 'Containers-Toolkit' }).Name -join ', '
    $message = "For unregistered services/daemons, check the tool's help or register the service using `n`t$registerCommands"
    Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
    return $installedTools
}

function Install-ContainerTools {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
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
        $CleanUp,

        [Switch]
        [parameter(HelpMessage = "Force install the tools even if they already exists at the specified path")]
        $Force,

        [switch]
        [parameter(HelpMessage = "Register and Start Conatinerd and Buildkitd services and set up NAT network")]
        $RegisterServices
    )

    begin {
        $toInstall = @("containerd", "buildkit", "nerdctl")
        $toInstallString = $($toInstall -join ', ')

        $WhatIfMessage = "$toInstallString will be installed"
        if ($Force) {
            <# Action when this condition is true #>
            $WhatIfMessage = "$toInstallString will be automativally uninstalled (if they are already installed) and reinstalled"
        }
        if ($CleanUp) {
            <# Action when this condition is true #>
            $WhatIfMessage += " and downloaded files will be removed"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($InstallPath, $WhatIfMessage)) {
            Write-Debug "Tools to install: $toInstallString"

            # Global Variables needed for the script
            $containerdTarFile = "containerd-${containerdVersion}-windows-amd64.tar.gz"
            $BuildKitTarFile = "buildkit-v${BuildKitVersion}.windows-amd64.tar.gz"
            $nerdctlTarFile = "nerdctl-${nerdctlVersion}-windows-amd64.tar.gz"

            # Installation paths
            $ContainerdPath = "$InstallPath\Containerd"
            $BuildkitPath = "$InstallPath\Buildkit"
            $NerdCTLPath = "$InstallPath\nerdctl"

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
                    Feature      = "nerdctl"
                    Uri          = "https://github.com/containerd/nerdctl/releases/download/v${nerdctlVersion}/$nerdctlTarFile"
                    Version      = $nerdctlVersion
                    DownloadPath = "$DownloadPath\$($nerdctlTarFile)"
                    InstallPath  = $NerdCTLPath
                    EnvPath      = $NerdCTLPath
                }
            )

            # Download files
            Get-InstallationFile -Files $files

            $completedInstalls = @()

            # Install tools
            foreach ($params in $files) {
                Write-Output "Installing $($params.Feature)"

                try {
                    # Uninstall if tool exists at specified location. Requires user consent
                    if (-not (Test-EmptyDirectory -Path $params.InstallPath) ) {
                        Write-Warning "Uninstalling $($params.Feature) from $($params.InstallPath)"
                        Uninstall-ContainerTool -Tool $params.Feature -Path $params.InstallPath -Force $force
                    }

                    # Untar downloaded files to the specified installation path
                    $InstallParams = @{
                        Feature      = $params.Feature
                        InstallPath  = $params.InstallPath
                        DownloadPath = $params.DownloadPath
                        EnvPath      = $params.EnvPath
                    }
                    Install-RequiredFeature @InstallParams -Cleanup $CleanUp

                    $completedInstalls += $params.Feature

                    if ($RegisterServices) {
                        $RegisterParams = @{
                            force = $force
                            feature = $params.Feature
                            installPath = $params.InstallPath
                        }
                        Register-Service @RegisterParams
                    }
                }
                catch {
                    Write-Error "Installation failed for $($params.feature). $_"
                }
            }

            if ($RegisterServices) {
                Initialize-NatNetwork
            }
            else {
                Write-Information -Tags "Instructions" -MessageData (
                    "To start containderd service, run 'Start-Service containerd' or 'Start-ContainerdService',",
                    "To start buildkitd service, run 'Start-Service buildkitd' or 'Start-BuildkitdService'"
                )
            }

            Write-Information -MessageData "$($completedInstalls -join ', ') installed successfully." -Tags "Installation" -InformationAction Continue

            $message = "To register containerd and buildkitd services, run the following commands:`n`tRegister-ContainerdService -ContainerdPath '$ContainerdPath' -Start`n`tRegister-BuildkitdService -BuildkitPath '$BuildkitPath' -Start"
            $message += "`nThen, to create a NAT network for nerdctl, run the following command:`n`tInitialize-NatNetwork"
            Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Uninstall-ContainerTool($Tool, $Path, $force) {
    $uninstallCommand = "Uninstall-$($Tool)"
    & $uninstallCommand -Path "$Path" -Force:$Force
}

function Get-InstalledVersion($feature, $Latest) {
    $executable = $null
    $daemon = $null
    switch ($feature) {
        "buildkit" {
            $bktdExecutable = (Get-Command "build*.exe" | Where-Object { $_.Source -like "*buildkit*" }) | Select-Object Name
            $executable = ($bktdExecutable[0]).Name

            if ($null -ne ($bktdExecutable | Where-Object { $_.Name -contains "buildkitd.exe" })) {
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
        $result = $result | Select-Object Tool, Installed, Version

        if ($daemon) {
            Add-Member -InputObject $result -Name 'Daemon' -Value $daemon -MemberType 'NoteProperty'
            Add-Member -InputObject $result -Name 'DaemonStatus' -MemberType 'NoteProperty' `
                -Value (getDaemonStatus -Daemon $daemon)
        }
    }

    # Get latest version
    $latestVersion = "-"
    if ($Latest) {
        $latestVersionCommand = "Get-$($feature)LatestVersion"
        $latestVersion = & $latestVersionCommand
        Add-Member -InputObject $result -Name 'LatestVersion' -Value "v$latestVersion" -MemberType 'NoteProperty'
    }

    return $result
}

function getToolVersion($executable) {
    $installedVersion = $null
    try {
        $version = & $executable -v

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

function Register-Service {
    param (
        [bool]$force,
        [string]$feature,
        [string]$installPath
    )

    switch ($feature) {
        "Containerd" {
            $RegisterParams = @{
                ContainerdPath = $installPath
            }
            Register-ContainerdService @RegisterParams -Start -Force:$force
        }
        "BuildKit" {
            $RegisterParams = @{
                BuildKitPath = $installPath
            }
            Register-BuildkitdService @RegisterParams -Start -Force:$force
        }
    }
}

Export-ModuleMember -Function Show-ContainerTools
Export-ModuleMember -Function Install-ContainerTools
Export-ModuleMember -Function Uninstall-ContainerTool
