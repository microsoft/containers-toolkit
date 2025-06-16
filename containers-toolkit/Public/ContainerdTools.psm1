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
        [Alias("Setup")]
        [switch]$RegisterService,

        [Parameter(HelpMessage = 'OS architecture to download files for. Default is $env:PROCESSOR_ARCHITECTURE')]
        [ValidateSet('amd64', '386', "arm", "arm64")]
        [string]$OSArchitecture = $env:PROCESSOR_ARCHITECTURE,

        [Switch]
        [parameter(HelpMessage = "Installs Containerd even if the tool already exists at the specified path")]
        $Force
    )

    begin {
        # Check if Containerd is already installed
        $isInstalled = -not (Test-EmptyDirectory -Path "$InstallPath\bin")

        $WhatIfMessage = "Containerd will be installed at '$InstallPath'"
        if ($isInstalled) {
            $WhatIfMessage = "Containerd will be uninstalled from and reinstalled at '$InstallPath'"
        }
        if ($Setup) {
            <# Action when this condition is true #>
            $WhatIfMessage = "Containerd will be installed at '$InstallPath' and containerd service will be registered and started"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            # Check if tool already exists at specified location
            if ($isInstalled) {
                $errMsg = "Containerd already exists at '$InstallPath' or the directory is not empty."
                Write-Warning $errMsg

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
            Write-Output "Downloading and installing Containerd v$version at $InstallPath"

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

            Write-Output "Containerd v$version successfully installed at $InstallPath `n"

            $showCommands = $true
            try {
                if ($RegisterService) {
                    Register-ContainerdService -ContainerdPath $InstallPath -Start -Force:$true
                    $showCommands = $false
                }
            }
            catch {
                Write-Warning "Failed to setup Containerd service. $_"
            }

            if ($showCommands) {
                $commands = (Get-command -Name '*containerd*' | Where-Object { $_.Source -like 'Containers-Toolkit' -and $_.Name -ne 'Install-Containerd' }).Name
                $message = "Other useful Containerd commands: $($commands -join ', ').`nTo learn more about each command, run Get-Help <command-name>, e.g., 'Get-Help Register-ContainerdService'"
                Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
            }

            Write-Output "For containerd usage: run 'containerd -h'`n"
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
                Write-Warning ( -join @("Containerd service already registered. To re-register the service, "
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
                Write-Error "containerd service registration cancelled."
                return
            }

            Write-Output "Configuring containerd service"

            Add-MpPreference -ExclusionProcess "$containerdExecutable"

            # Get default containerd config and write to file
            $containerdConfigFile = "$ContainerdPath\config.toml"
            Write-Debug "Containerd config file: $containerdConfigFile"

            $output = Invoke-ExecutableCommand -Executable "$containerdExecutable" -Arguments "config default"
            $output.StandardOutput.ReadToEnd() | Out-File -FilePath $containerdConfigFile -Encoding ascii -Force

            # Check config file is not empty
            $isEmptyConfig = Test-ConfFileEmpty -Path  "$containerdConfigFile"
            if ($isEmptyConfig) {
                Throw "Config file is empty. '$containerdConfigFile'"
            }

            Write-Output "Review containerd configutations at $containerdConfigFile"

            # Register containerd service
            $output = Invoke-ExecutableCommand -Executable "$containerdExecutable" -Arguments "--register-service --log-level debug --service-name containerd --log-file `"$env:TEMP\containerd.log`""
            if ($output.ExitCode -ne 0) {
                Throw "Failed to register containerd service. $($output.StandardError.ReadToEnd())"
            }

            $containerdService = Get-Service -Name containerd -ErrorAction SilentlyContinue
            if ($null -eq $containerdService ) {
                Throw "Failed to register containerd service. $($Error[0].Exception.Message)"
            }

            Set-Service containerd -StartupType Automatic
            Write-Output "Successfully registered Containerd service."

            if ($Start) {
                Start-ContainerdService
                Write-Output "Successfully started Containerd service."
            }
            else {
                Write-Information -InformationAction Continue -MessageData "To start containerd service, run 'Start-Service containerd' or 'Start-ContainerdService'"
            }

            Write-Debug $(Get-Service 'containerd' -ErrorAction SilentlyContinue | Format-Table -AutoSize | Out-String)
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
        [String]$Path = "$ENV:ProgramFiles\Containerd",

        [parameter(HelpMessage = "Delete all Containerd program files and program data")]
        [Switch] $Purge,

        [parameter(HelpMessage = "Bypass confirmation to uninstall Containerd")]
        [Switch] $Force
    )

    begin {
        $tool = 'Containerd'
        if (!$Path) {
            $Path = Get-DefaultInstallPath -Tool $tool
        }

        # If we are not purging, we are uninstalling from the bin directory
        # that contains the containerd binaries, containerd/bin
        $path = $path.TrimEnd("\")
        if (-not $Purge -and (-not $path.EndsWith("\bin"))) {
            $path = $path.Trim() + "\bin"
        }

        $WhatIfMessage = "Containerd will be uninstalled from '$path' and containerd service will be stopped and unregistered."
        if ($Purge) {
            $WhatIfMessage += " Containerd program data will also be removed."
        }
        else {
            $WhatIfMessage += " Containerd program data won't be removed. To remove program data, run 'Uninstall-Containerd' command without -Purge flag."
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            $consent = $force
            if (!$ENV:PESTER) {
                $consent = $force -or $PSCmdlet.ShouldContinue($Path, 'Are you sure you want to uninstall Containerd?')
            }

            if (!$consent) {
                Write-Warning "$tool uninstallation cancelled."
                return
            }

            Write-Warning "Uninstalling preinstalled $tool at the path '$path'.`n$WhatIfMessage"
            try {
                Uninstall-ContainerdHelper -Path "$path" -Purge:$Purge
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
        [String]$Path,

        [parameter(HelpMessage = "Remove all program data for Containerd")]
        [Switch] $Purge
    )

    if (-not (Test-EmptyDirectory -Path "$Path")) {
        try {
            if (Test-ServiceRegistered -Service 'containerd') {
                Stop-ContainerdService
                Unregister-Containerd -ContainerdPath "$Path"
            }
        }
        catch {
            Throw "Could not stop or unregister containerd service. $_"
        }

        # Remove the folder where containerd is installed and related folders
        Remove-Item -Path "$Path" -Recurse -Force
    }

    if ($Purge) {
        Write-Output "Purging Containerd program data"

        # Delete the containerd key
        Write-Warning "Removing Containerd registry key"
        Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\containerd" -Recurse -Force -ErrorAction Ignore

        # Delete containerd programdata
        Write-Warning "Removing Containerd program data"
        Uninstall-ProgramFiles "$ENV:ProgramData\Containerd"

        # Remove from env path
        Write-Warning "Removing Containerd from env path"
        Remove-FeatureFromPath -Feature "containerd"
    }

    Write-Output "Successfully uninstalled Containerd."
}

function Unregister-Containerd ($containerdPath) {
    if (!(Test-ServiceRegistered -Service 'Containerd')) {
        Write-Warning "Containerd service does not exist as an installed service."
        return
    }

    # Unregister containerd service
    $containerdExecutable = (Get-ChildItem -Path "$ContainerdPath" -Recurse -Filter "containerd.exe").FullName | Select-Object -First 1
    $output = Invoke-ExecutableCommand -Executable "$containerdExecutable" -Arguments "--unregister-service"
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
