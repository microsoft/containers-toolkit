###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

using module "..\Private\CommonToolUtilities.psm1"

$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force


function Get-ContainerdLatestVersion {
    $latestVersion = Get-LatestToolVersion -Tool "containerd"
    return $latestVersion
}

function Install-Containerd {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param(
        [parameter(HelpMessage = "ContainerD version to use. Defaults to 'latest'")]
        [string]$Version = "latest",

        [parameter(HelpMessage = "Path to install containerd. Defaults to ~\program files\containerd")]
        [string]$InstallPath = "$Env:ProgramFiles\Containerd",

        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        [string]$DownloadPath = "$HOME\Downloads",

        [Parameter(HelpMessage = "Register and start Containerd Service")]
        [switch]$Setup,

        [Parameter(HelpMessage = 'OS architecture to download files for. Default is $env:PROCESSOR_ARCHITECTURE')]
        [ValidateSet('amd64', '386', "arm", "arm64")]
        [string]$OSArchitecture = $env:PROCESSOR_ARCHITECTURE,

        [Switch]
        [parameter(HelpMessage = "Installs Containerd even if the tool already exists at the specified path")]
        $Force
    )

    begin {
        # Check if Containerd is alread installed
        $isInstalled = -not (Test-EmptyDirectory -Path $InstallPath)

        $WhatIfMessage = "Containerd will be installed at $InstallPath"
        if ($isInstalled) {
            $WhatIfMessage = "Containerd will be uninstalled from and reinstalled at $InstallPath"
        }
        if ($Setup) {
            <# Action when this condition is true #>
            $WhatIfMessage = "Containerd will be installed at $InstallPath and containerd service will be registered and started"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            # Check if tool already exists at specified location
            if ($isInstalled) {
                $errMsg = "Containerd already exists at $InstallPath or the directory is not empty"
                [Logger]::Warning($errMsg)

                # Uninstall if tool exists at specified location. Requires user consent
                try {
                    Uninstall-Containerd -Path "$InstallPath" -Confirm:$false -Force:$Force | Out-Null
                }
                catch {
                    Throw "Containerd installation failed. $_"
                }
            }

            # Get Containerd version to install
            if (!$Version) {
                # Get default version
                $Version = Get-ContainerdLatestVersion
            }
            $Version = $Version.TrimStart('v')
            [Logger]::Info("Downloading and installing Containerd v$version at $InstallPath")

            # Download files
            $downloadParams = @{
                ToolName           = "Containerd"
                Repository         = "$CONTAINERD_REPO"
                Version            = $version
                OSArchitecture     = $OSArchitecture
                DownloadPath       = $DownloadPath
                ChecksumSchemaFile = $null

                # QUESTION: Do we need them all? Containerd release contains multiple files. containerd, cri-containerd, cri-containerd-cni
                # Matches eg: containerd-1.7.21-windows-amd64.tar.gz and containerd-1.7.21-windows-amd64.tar.gz.sha256sum
                FileFilterRegEx    = "(?:^containerd-<__VERSION__>-windows-$OSArchitecture.*.tar.gz(.*)?)$"
            }
            $downloadParamsProperties = [FileDownloadParameters]::new(
                $downloadParams.ToolName,
                $downloadParams.Repository,
                $downloadParams.Version,
                $downloadParams.OSArchitecture,
                $downloadParams.DownloadPath,
                $downloadParams.ChecksumSchemaFile,
                $downloadParams.FileFilterRegEx
            )
            $sourceFile = Get-InstallationFile -FileParameters $downloadParamsProperties

            # Untar and install tool
            $params = @{
                Feature     = "containerd"
                InstallPath = $InstallPath
                SourceFile  = $sourceFile
                EnvPath     = "$InstallPath\bin"
                cleanup     = $true
            }
            Install-RequiredFeature @params

            [Logger]::Info("Containerd v$version successfully installed at $InstallPath `n")

            $showCommands = $true
            try {
                if ($Setup) {
                    Register-ContainerdService -ContainerdPath $InstallPath -Start -Force:$true
                    $showCommands = $false
                }
            }
            catch {
                [Logger]::Warning("Failed to setup Containerd service. $_")
            }

            if ($showCommands) {
                $commands = (Get-command -Name '*containerd*' | Where-Object { $_.Source -like 'Containers-Toolkit' -and $_.Name -ne 'Install-Containerd' }).Name
                $message = "Other useful Containerd commands: $($commands -join ', ').`nTo learn more about each command, run Get-Help <command-name>, e.g., 'Get-Help Register-ContainerdService'"
                [Logger]::Info($message)
            }

            [Logger]::Info("For containerd usage: run 'containerd -h'`n")
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

# YAGNI: Is this necessary?
function Build-ContainerdFromSource {
    Throw "Method or operation not implemented."
}

function Start-ContainerdService {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param()

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Starts containerd service")) {
            Invoke-ServiceAction -Service 'Containerd' -Action 'Start'
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Stop-ContainerdService {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param()

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Stop containerd service")) {
            Invoke-ServiceAction -Service 'Containerd' -Action 'Stop'
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Register-ContainerdService {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [parameter(HelpMessage = "Containerd path")]
        [String]$ContainerdPath,

        [parameter(HelpMessage = "Specify to start Containerd service after registration is complete")]
        [Switch]$Start,

        [parameter(HelpMessage = "Bypass confirmation to register containerd service")]
        [Switch]$Force
    )

    begin {
        if (!$ContainerdPath) {
            $ContainerdPath = Get-DefaultInstallPath -Tool "containerd"
        }

        $containerdExecutable = "$ContainerdPath\bin\containerd.exe"

        $WhatIfMessage = 'Registers containerd service.'
        if ($Start) {
            $WhatIfMessage = "Registers and starts containerd service."
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            if (Test-EmptyDirectory -Path $ContainerdPath) {
                Throw "Containerd does not exist at $ContainerdPath or the directory is empty"
            }

            # Check containerd service is already registered
            if (Test-ServiceRegistered -Service 'containerd') {
                [Logger]::Warning( -join @("Containerd service already registered. To re-register the service, "
                        "stop the service by running 'Stop-Service containerd' or 'Stop-ContainerdService', then "
                        "run 'containerd --unregister-service'. Wait for containerd service to be deregistered, "
                        "then re-reun this command."))
                return
            }

            $consent = $force
            if (!$ENV:PESTER) {
                $consent = $force -or $PSCmdlet.ShouldContinue('', "Are you sure you want to register containerd service?")
            }

            if (!$consent) {
                [Logger]::Error("containerd service registration cancelled.")
                return
            }

            [Logger]::Info("Configuring containerd service")

            Add-MpPreference -ExclusionProcess $containerdExecutable

            # Get default containerd config and write to file
            $containerdConfigFile = "$ContainerdPath\config.toml"
            [Logger]::Debug("Containerd config file: $containerdConfigFile")

            $output = Invoke-ExecutableCommand -Executable $containerdExecutable -Arguments "config default"
            $output.StandardOutput.ReadToEnd() | Out-File -FilePath $containerdConfigFile -Encoding ascii -Force

            # Check config file is not empty
            $isEmptyConfig = Test-ConfFileEmpty -Path  "$containerdConfigFile"
            if ($isEmptyConfig) {
                Throw "Config file is empty. '$containerdConfigFile'"
            }

            [Logger]::Info("Review containerd configutations at $containerdConfigFile")

            # Register containerd service
            $output = Invoke-ExecutableCommand -Executable $containerdExecutable -Arguments "--register-service --log-level debug --service-name containerd --log-file `"$env:TEMP\containerd.log`""
            if ($output.ExitCode -ne 0) {
                Throw "Failed to register containerd service. $($output.StandardError.ReadToEnd())"
            }

            $containerdService = Get-Service -Name containerd -ErrorAction SilentlyContinue
            if ($null -eq $containerdService ) {
                Throw "Failed to register containerd service. $($Error[0].Exception.Message)"
            }

            Set-Service containerd -StartupType Automatic
            [Logger]::Info("Successfully registered Containerd service.")

            if ($Start) {
                Start-ContainerdService
                [Logger]::Info("Successfully started Containerd service.")
            }
            else {
                [Logger]::Info("To start containerd service, run 'Start-Service containerd' or 'Start-ContainerdService'")
            }

            [Logger]::Debug($(Get-Service 'containerd' -ErrorAction SilentlyContinue | Format-Table -AutoSize | Out-String))
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Uninstall-Containerd {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [parameter(HelpMessage = "Containerd path")]
        [String]$Path,

        [parameter(HelpMessage = "Bypass confirmation to uninstall Containerd")]
        [Switch] $Force
    )

    begin {
        $tool = 'Containerd'
        if (!$Path) {
            $Path = Get-DefaultInstallPath -Tool $tool
        }

        $WhatIfMessage = "Containerd will be uninstalled from $path and containerd service will be stopped and unregistered"
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            if (Test-EmptyDirectory -Path $path) {
                [Logger]::Info("$tool does not exist at $Path or the directory is empty")
                return
            }

            $consent = $force
            if (!$ENV:PESTER) {
                $consent = $force -or $PSCmdlet.ShouldContinue($Path, 'Are you sure you want to uninstall Containerd?')
            }

            if (!$consent) {
                Throw "$tool uninstallation cancelled."
            }

            [Logger]::Warning("Uninstalling preinstalled $tool at the path $path")
            try {
                Uninstall-ContainerdHelper -Path $path
            }
            catch {
                Throw "Could not uninstall $tool. $_"
            }
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Uninstall-ContainerdHelper {
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory = $true, HelpMessage = "Containerd path")]
        [String]$Path
    )

    if (Test-EmptyDirectory -Path $Path) {
        [Logger]::Error("Containerd does not exist at $Path or the directory is empty.")
        return
    }

    try {
        if (Test-ServiceRegistered -Service 'containerd') {
            Stop-ContainerdService
            Unregister-Containerd -ContainerdPath $Path
        }
    }
    catch {
        Throw "Could not stop or unregister containerd service. $_"
    }

    # Delete the containerd key
    Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\containerd" -Recurse -Force -ErrorAction Ignore

    # Remove the folder where containerd is installed and related folders
    Remove-Item -Path $Path -Recurse -Force

    # Delete containerd programdata
    Uninstall-ProgramFiles "$ENV:ProgramData\Containerd"

    # Remove from env path
    Remove-FeatureFromPath -Feature "containerd"

    [Logger]::Info("Successfully uninstalled Containerd.")
}

function Unregister-Containerd ($containerdPath) {
    if (!(Test-ServiceRegistered -Service 'Containerd')) {
        [Logger]::Warning("Containerd service does not exist as an installed service.")
        return
    }

    # Unregister containerd service
    $containerdExecutable = "$ContainerdPath\bin\containerd.exe"
    $output = Invoke-ExecutableCommand -Executable $containerdExecutable -Arguments "--unregister-service"
    if ($output.ExitCode -ne 0) {
        Throw "Could not unregister containerd service. $($output.StandardError.ReadToEnd())"
    }
    else {
        # Wait for service to be unregistered
        # Failure to wait causes "The specified service has been marked for deletion." error
        Start-Sleep -Seconds 15
    }
}


Export-ModuleMember -Function Get-ContainerdLatestVersion
Export-ModuleMember -Function Install-Containerd
Export-ModuleMember -Function Start-ContainerdService -Alias Start-Containerd
Export-ModuleMember -Function Stop-ContainerdService -Alias Stop-Containerd
Export-ModuleMember -Function Register-ContainerdService
Export-ModuleMember -Function Uninstall-Containerd, Uninstall-ContainerdHelper
