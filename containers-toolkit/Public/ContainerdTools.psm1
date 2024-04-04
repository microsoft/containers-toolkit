###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force

function Get-ContainerdLatestVersion {
    $latestVersion = Get-LatestToolVersion -Repository "containerd/containerd"
    return $latestVersion
}

function Install-Containerd {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param(
        [parameter(HelpMessage = "ContainerD version to use. Defaults to latest version")]
        [string]$Version,

        [parameter(HelpMessage = "Path to install containerd. Defaults to ~\program files\containerd")]
        [string]$InstallPath = "$Env:ProgramFiles\Containerd",

        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        [string]$DownloadPath = "$HOME\Downloads",

        [Parameter(HelpMessage = "Register and start Containerd Service")]
        [switch] $Setup,

        [Switch]
        [parameter(HelpMessage = "Installs Containerd even if the tool already exists at the specified path")]
        $Force
    )

    begin {
        # Check if Containerd is alread installed
        $isInstalled = -not (Test-EmptyDirectory -Path $InstallPath)

        $WhatIfMessage = "Containerd will be installed"
        if ($isInstalled) {
            $WhatIfMessage = "Containerd will be uninstalled and reinstalled"
        }
        if ($Setup) {
            <# Action when this condition is true #>
            $WhatIfMessage = "Containerd will be installed and containerd service will be registered and started"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($InstallPath, $WhatIfMessage)) {
            # Check if tool already exists at specified location
            if ($isInstalled) {
                $errMsg = "Containerd already exists at $InstallPath or the directory is not empty"
                Write-Warning $errMsg

                # Uninstall if tool exists at specified location. Requires user consent
                try {
                    $command = "Uninstall-Containerd -Path '$InstallPath' -Force:`$$Force | Out-Null"
                    Invoke-Expression -Command $command
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

            $containerdTarFile = "containerd-${version}-windows-amd64.tar.gz"
            $DownloadPath = "$DownloadPath\$($containerdTarFile)"

            # Download files
            $DownloadParams = @(
                @{
                    Feature      = "Containerd"
                    Uri          = "https://github.com/containerd/containerd/releases/download/v$version/$($containerdTarFile)"
                    Version      = $version
                    DownloadPath = $DownloadPath
                }
            )
            Get-InstallationFiles -Files $DownloadParams

            # Untar and install tool
            $params = @{
                Feature      = "containerd"
                InstallPath  = $InstallPath
                DownloadPath = $DownloadPath
                EnvPath      = "$InstallPath\bin"
                cleanup      = $true
            }
            Install-RequiredFeature @params

            Write-Output "Containerd v$version successfully installed at $InstallPath `n"

            $showCommands = $true
            try {
                if ($Setup) {
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

            Write-Host "For containerd usage: run 'containerd -h'" -ForegroundColor DarkGreen
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
    Invoke-ServiceAction -Service 'Containerd' -Action 'Start'
}

function Stop-ContainerdService {
    Invoke-ServiceAction -Service 'Containerd' -Action 'Stop'
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
        if ($PSCmdlet.ShouldProcess($containerdExecutable, $WhatIfMessage)) {
            if (Test-EmptyDirectory -Path $ContainerdPath) {
                Throw "Containerd does not exist at $ContainerdPath or the directory is empty"
            }

            # Check containerd service is already registered
            if (Test-ServiceRegistered -Service 'containerd') {
                Write-Warning "Containerd service already registered."
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

            Add-MpPreference -ExclusionProcess $containerdExecutable

            #Configure containerd service
            $containerdConfigFile = "$ContainerdPath\config.toml"
            Invoke-Expression -Command "& '$containerdExecutable' config default" | Out-File $containerdConfigFile -Encoding ascii
            Write-Information -InformationAction Continue -MessageData "Review containerd configutations at $containerdConfigFile"

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
        ConfirmImpact = 'Medium'
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

        $WhatIfMessage = "Containerd will be uninstalled and containerd service will be stopped and unregistered"
    }

    process {
        if ($PSCmdlet.ShouldProcess($Path, $WhatIfMessage)) {
            if (Test-EmptyDirectory -Path $path) {
                Write-Output "$tool does not exist at $Path or the directory is empty"
                return
            }

            $consent = $force
            if (!$ENV:PESTER) {
                $consent = $force -or $PSCmdlet.ShouldContinue($Path, 'Are you sure you want to uninstall Containerd?')
            }

            if (!$consent) {
                Throw "$tool uninstallation cancelled."
            }

            Write-Warning "Uninstalling preinstalled $tool at the path $path"
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
        Write-Error "Containerd does not exist at $Path or the directory is empty."
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

    # FIXME: Access to the path denied
    Remove-Item -Path "$ENV:ProgramData\Containerd" -Recurse -Force -ErrorAction Ignore

    # Remove from env path
    Remove-FeatureFromPath -Feature "containerd"

    Write-Output "Successfully uninstalled Containerd."
}

function Unregister-Containerd ($containerdPath) {
    if (!(Test-ServiceRegistered -Service 'Containerd')) {
        Write-Warning "Containerd service does not exist as an installed service."
        return
    }

    # Unregister containerd service
    $containerdExecutable = "$ContainerdPath\bin\containerd.exe"
    $output = Invoke-ExecutableCommand -Executable $containerdExecutable -Arguments "--unregister-service"
    if ($output.ExitCode -ne 0) {
        Throw "Could not unregister containerd service. $($output.StandardError.ReadToEnd())"
    }
    else {
        Start-Sleep -Seconds 15
    }
}


Export-ModuleMember -Function Get-ContainerdLatestVersion
Export-ModuleMember -Function Install-Containerd
Export-ModuleMember -Function Start-ContainerdService -Alias Start-Containerd
Export-ModuleMember -Function Stop-ContainerdService -Alias Stop-Containerd
Export-ModuleMember -Function Register-ContainerdService
Export-ModuleMember -Function Uninstall-Containerd, Uninstall-ContainerdHelper
