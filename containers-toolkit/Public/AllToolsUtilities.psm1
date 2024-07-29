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

        [Switch]
        [parameter(HelpMessage = "Force install the tools even if they already exists at the specified path")]
        $Force,

        [switch]
        [parameter(HelpMessage = "Register and Start Containerd and Buildkitd services and set up NAT network")]
        $RegisterServices
    )

    begin {
        # Strip leading "v" from version
        $containerdVersion = $containerdVersion.TrimStart("v")
        $buildKitVersion = $buildKitVersion.TrimStart("v")
        $nerdctlVersion = $nerdctlVersion.TrimStart("v")

        $toInstall = @("containerd v$containerdVersion", "buildkit v$buildKitVersion", "nerdctl v$nerdctlVersion")
        $toInstallString = $($toInstall -join ', ')

        $WhatIfMessage = "$toInstallString will be installed. Any downloaded files will be removed"
        if ($Force) {
            $WhatIfMessage = "$toInstallString will be automatically uninstalled (if they are already installed) and reinstalled. Any downloaded files will be removed"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($InstallPath, $WhatIfMessage)) {
            Write-Output "The following tools will be installed: $toInstallString"

            Write-Debug "Downloading files to $DownloadPath"
            Write-Debug "Installing files to $InstallPath"

            $completedInstalls = @()
            $failedInstalls = @()

            $installTasks = @(
                @{
                    name     = "Containerd"
                    function = {
                        Install-Containerd -Force:$force -Confirm:$false `
                            -Version $containerdVersion `
                            -InstallPath "$InstallPath\Containerd" `
                            -DownloadPath "$DownloadPath" `
                            -Setup:$RegisterServices
                    }
                },
                @{
                    name     = "Buildkit"
                    function = {
                        Install-Buildkit -Force:$force -Confirm:$false `
                            -Version $buildKitVersion `
                            -InstallPath "$InstallPath\Buildkit" `
                            -DownloadPath "$DownloadPath" `
                            -Setup:$RegisterServices
                    }
                },
                @{
                    name     = "nerdctl"
                    function = {
                        Install-Nerdctl -Force:$force -Confirm:$false `
                            -Version $nerdctlVersion `
                            -InstallPath "$InstallPath\nerdctl" `
                            -DownloadPath "$DownloadPath"
                    }
                }
            )

            foreach ($task in $installTasks) {
                try {
                    & $task.Function
                    $completedInstalls += $task.Name
                }
                catch {
                    Write-Error "$($task.Name) Installation failed. $_"
                    $failedInstalls += $task.Name
                }
            }

            if ($completedInstalls) {
                Write-Output "$($completedInstalls -join ', ') installed successfully.`n"
            }

            if ($failedInstalls) {
                Write-Warning "Installation failed for $($failedInstalls -join ', ')`n"
            }

            if ($RegisterServices) {
                try {
                    Initialize-NatNetwork -Force:$force -Confirm:$false
                }
                catch {
                    Write-Error "Failed to initialize NAT network. $_"
                }
            }
            else {
                $message = @"
To register containerd and buildkitd services and create a NAT network, see help on the following commands:
    Get-Help Register-ContainerdService
    Get-Help Register-BuildkitdService
    Get-Help Initialize-NatNetwork
"@
                Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
            }

            Write-Output "Installation complete. See logs for more details"
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Get-InstalledVersion($feature, $Latest) {
    $executable = $null
    $daemon = $null
    switch ($feature) {
        "buildkit" {
            $bktdExecutable = (Get-Command "build*.exe" | Where-Object { $_.Source -like "*buildkit*" }) | Select-Object Name
            if ($bktdExecutable) {
                $executable = ($bktdExecutable[0]).Name
            }

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

Export-ModuleMember -Function Show-ContainerTools
Export-ModuleMember -Function Install-ContainerTools
