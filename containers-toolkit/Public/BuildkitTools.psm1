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

function Get-BuildkitLatestVersion {
    $latestVersion = Get-LatestToolVersion -Tool "buildkit"
    return $latestVersion
}

function Install-Buildkit {
    [CmdletBinding(
        DefaultParameterSetName = 'Install',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Setup')]
        [parameter(HelpMessage = "Buildkit version to use. Defaults to 'latest'")]
        [string]$Version = "latest",

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Setup')]
        [parameter(HelpMessage = "Path to install buildkit. Defaults to ~\program files\buildkit")]
        [string]$InstallPath = "$Env:ProgramFiles\Buildkit",

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Setup')]
        [parameter(HelpMessage = "Path to download files. Defaults to user's Downloads folder")]
        [string]$DownloadPath = "$HOME\Downloads",

        [Parameter(ParameterSetName = 'Setup')]
        [Parameter(HelpMessage = "Register the buildkitd service.")]
        [Alias("Setup")]
        [switch]$RegisterService,

        [Parameter(ParameterSetName = 'Setup')]
        [Parameter(HelpMessage = "Path to Windows CNI plugin. Defaults to `$ENV:ProgramFiles\Containerd\cni")]
        [string]$WinCNIPath,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Setup')]
        [Parameter(HelpMessage = 'OS architecture to download files for. Default is $env:PROCESSOR_ARCHITECTURE')]
        [ValidateSet('amd64', '386', "arm", "arm64")]
        [string]$OSArchitecture = $env:PROCESSOR_ARCHITECTURE,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Setup')]
        [parameter(HelpMessage = "Installs Buildkit even if the tool already exists at the specified path")]
        [Switch]$Force
    )

    begin {
        # Check if Buildkit is alread installed
        $isInstalled = -not (Test-EmptyDirectory -Path $InstallPath)

        $WhatIfMessage = "Buildkit will be installed at '$InstallPath'"
        if ($isInstalled) {
            $WhatIfMessage = "Buildkit will be uninstalled from and reinstalled at '$InstallPath'"
        }
        if ($Setup) {
            <# Action when this condition is true #>
            $WhatIfMessage = "Buildkit will be installed at '$InstallPath' and buildkitd service will be registered and started"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            # Check if tool already exists at specified location
            if ($isInstalled) {
                $errMsg = "Buildkit already exists at '$InstallPath' or the directory is not empty."
                Write-Warning $errMsg

                # Uninstall if tool exists at specified location. Requires user consent
                try {
                    Uninstall-Buildkit -Path "$InstallPath" -Force:$Force -Confirm:$false | Out-Null
                }
                catch {
                    Throw "Buildkit installation failed. $_"
                }
            }

            # Get Buildkit version to install
            if (!$Version) {
                $Version = Get-BuildkitLatestVersion
            }
            $Version = $Version.TrimStart('v')

            Write-Output "Downloading and installing Buildkit v$Version at $InstallPath"

            # Download files
            $downloadParams = @{
                ToolName           = "Buildkit"
                Repository         = "$BUILDKIT_REPO"
                Version            = $Version
                OSArchitecture     = $OSArchitecture
                DownloadPath       = $DownloadPath
                ChecksumSchemaFile = "$ModuleParentPath\Private\schemas\in-toto.sbom.schema.json"
                FileFilterRegEx    = $null
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

            # Untar downloaded file at install path
            $params = @{
                Feature     = "Buildkit"
                InstallPath = $InstallPath
                SourceFile  = "$sourceFile"
                EnvPath     = "$InstallPath\bin"
                cleanup     = $true
            }
            Install-RequiredFeature @params

            Write-Output "Successfully installed Buildkit v$Version at $InstallPath`n"

            # Register Buildkitd service
            $showCommands = $true
            try {
                if ($Setup) {
                    Register-BuildkitdService -BuildKitPath $InstallPath -WinCNIPath $WinCNIPath -Start -Force:$true
                    $showCommands = $false
                }
            }
            catch {
                Write-Warning "Failed to registed and start Buildkitd service. $_"
            }

            if ($showCommands) {
                $commands = (Get-command -Name '*buildkit*' | Where-Object { $_.Source -like 'Containers-Toolkit' -and $_.Name -ne 'Install-Buildkit' }).Name
                $message = "Other useful Buildkit commands: $($commands -join ', ').`nTo learn more about each command, run Get-Help <command-name>, e.g., 'Get-Help `"*buildkit*`"' or 'Get-Help Register-BuildkitdService'`n"
                Write-Information -MessageData $message -Tags "Instructions" -InformationAction Continue
            }

            # Show buildkit binaries help
            (Get-command -Name "buildctl","buildkitd" -ErrorAction SilentlyContinue) | ForEach-Object {
                $executable = $_.Name
                # Remove extension from executable
                $commandName = $executable -replace ".exe", ""
                $message = "For $commandName usage: run `"$executable -h`""
                Write-Information -MessageData "$message`n" -Tags "Instructions" -InformationAction Continue
            }
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

# YAGNI: Is this necessary?
function Build-BuildkitFromSource {
    Throw "Method or operation not implemented."
}

function Start-BuildkitdService {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param()

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Buildkitd service will be started")) {
            Invoke-ServiceAction -Service 'Buildkitd' -Action 'Start'
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Stop-BuildkitdService {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param()

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Buildkitd service will be stopped")) {
            Invoke-ServiceAction -Service 'Buildkitd' -Action 'Stop'
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Register-BuildkitdService {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [parameter(HelpMessage = "Windows CNI plugin path. Defaults to `$ENV:ProgramFiles\Containerd\cni")]
        [String]$WinCNIPath= "$ENV:ProgramFiles\Containerd\cni",

        [parameter(HelpMessage = "Buildkit path. Defaults to `$ENV:ProgramFiles\Buildkit")]
        [String]$BuildKitPath= "$ENV:ProgramFiles\Buildkit",

        [parameter(HelpMessage = "Specify to start Buildkitd service after registration is complete")]
        [Switch]$Start,

        [parameter(HelpMessage = "Bypass confirmation to register buildkitd service")]
        [Switch]$Force
    )

    begin {
        if (!$BuildKitPath) {
            $BuildKitPath = Get-DefaultInstallPath -Tool "Buildkit"
        }

        $WhatIfMessage = 'Registers buildkitd service.'
        if ($Start) {
            $WhatIfMessage = "Registers and starts buildkitd service."
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            if (Test-EmptyDirectory -Path $BuildKitPath) {
                Throw "Buildkit does not exist at $BuildKitPath or the directory is empty"
            }

            # If buildkitd is not installed, terminate execution
            if (!(Test-BuildkitdServiceExists -BuildkitPath $BuildkitPath)) {
                Write-Error "Buildkitd executable not installed."
                return
            }

            # Check buildkitd service is already registered
            if (Test-ServiceRegistered -Service 'Buildkitd') {
                Write-Warning ( -join @("buildkitd service already registered. To re-register the service, "
                        "stop the service by running 'Stop-Service buildkitd' or 'Stop-BuildkitdService', then "
                        "run 'buildkitd --unregister-service'. Wait for buildkitd service to be deregistered, "
                        "then re-reun this command."))
                return
            }

            if (!$force) {
                if (!$ENV:PESTER) {
                    if (-not ($PSCmdlet.ShouldContinue('', "Are you sure you want to register buildkitd service?"))) {
                        Write-Error "buildkitd service registration cancelled."
                        return
                    }
                }
            }

            Write-Output "Configuring buildkitd service"

            $buildkitdExecutable = "$BuildKitPath\bin\buildkitd.exe"
            Write-Debug "Buildkitd path: $buildkitdExecutable"

            # Add buildkitd to Windows Defender exclusion list
            Add-MpPreference -ExclusionProcess $buildkitdExecutable

            if (!$WinCNIPath) {
                $containerdPath = Get-DefaultInstallPath -Tool "containerd"
                $WinCNIPath = "$containerdPath\cni"
            }

            $cniBinDir = "$WinCNIPath\bin"
            $cniConfPath = "$WinCNIPath\conf\0-containerd-nat.conf"
            Write-Debug "CNI bin dir: $cniBinDir"
            Write-Debug "CNI conf path: $cniConfPath"

            # Register buildkit service
            $command = "$buildkitdExecutable --register-service --debug --containerd-worker=true --containerd-cni-config-path=`"$cniConfPath`" --containerd-cni-binary-dir=`"$cniBinDir`" --service-name buildkitd"
            if (Test-ConfFileEmpty -Path $cniConfPath) {

                $consent = $force
                if (!$force) {
                    $consent = [ActionConsent](Get-ConsentToRegisterBuildkit -Path $cniConfPath) -eq [ActionConsent]::Yes
                }

                if ($consent) {
                    Write-Warning "Containerd conf file not found at $cniConfPath. Buildkit service will be registered without Containerd cni configurations."
                    $command = "$buildkitdExecutable --register-service --debug --containerd-worker=true --service-name buildkitd"
                }
                else {
                    Write-Error "Failed to register buildkit service. Containerd conf file not found at $cniConfPath.`n`t1. Ensure that the required CNI plugins are installed or you can install them using 'Install-WinCNIPlugin'.`n`t2. Create the file to resolve this issue .`n`t3. Rerun this command  'Register-BuildkitdService'"
                    Throw "Failed to register buildkit service. Containerd conf file not found at $cniConfPath."
                }
            }

            # remove the executable extension from the command
            $escapedPath = [regex]::Escape($buildkitdExecutable)
            $arguments = ($command -replace "$escapedPath", "").Trim()

            # Register the service
            $output = Invoke-ExecutableCommand -Executable $buildkitdExecutable -Arguments $arguments
            if ($output.ExitCode -ne 0) {
                Throw "Failed to register buildkitd service. $($output.StandardError.ReadToEnd())"
            }

            $buildkitdService = Get-Service buildkitd -ErrorAction SilentlyContinue
            if ($null -eq $buildkitdService ) {
                Throw "Failed to register buildkitd service. $($Error[0].Exception.Message)"
            }

            Set-Service buildkitd -StartupType Automatic
            Write-Output "Successfully registered Buildkitd service."

            $output = Invoke-ExecutableCommand -Executable 'sc.exe' -arguments 'config buildkitd depend=containerd'
            if ($output.ExitCode -ne 0) {
                Write-Error "Failed to set dependency for buildkitd on containerd. $($output.StandardOutput.ReadToEnd())"
            }

            if ($Start) {
                Start-BuildkitdService
                Write-Output "Successfully started Buildkitd service."
            }
            else {
                Write-Information -InformationAction Continue -MessageData "To start buildkitd service, run 'Start-Service buildkitd' or 'Start-BuildkitdService'"
            }

            Write-Debug $(Get-Service 'buildkitd' -ErrorAction SilentlyContinue | Format-Table -AutoSize | Out-String)

            # YAGNI: Do we need a buildkitd.toml on Windows?
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Uninstall-Buildkit {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [parameter(HelpMessage = "BuildKit path")]
        [String]$Path = "$ENV:ProgramFiles\Buildkit",

        [parameter(HelpMessage = "Delete all Buildkit program files and program data")]
        [Switch] $Purge,

        [parameter(HelpMessage = "Bypass confirmation to uninstall BuildKit")]
        [Switch] $Force
    )

    begin {
        $tool = 'Buildkit'
        if (!$Path) {
            $Path = Get-DefaultInstallPath -Tool $tool
        }

        # If we are not purging, we are uninstalling from the bin directory
        # that contains the buildkit binaries, buildkit/bin
        $path = $path.TrimEnd("\")
        if (-not $Purge -and (-not $path.EndsWith("\bin"))) {
            $path = $path.Trim() + "\bin"
        }

        $WhatIfMessage = "Buildkit will be uninstalled from '$path' and buildkitd service will be stopped and unregistered."
        if ($Purge) {
            $WhatIfMessage += " Buildkit program data will also be removed."
        }
        else {
            $WhatIfMessage += " Buildkit program data won't be removed. To remove program data, run 'Uninstall-Buildkit' command without -Purge flag."
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            if (Test-EmptyDirectory -Path "$path") {
                Write-Output "$tool does not exist at '$Path' or the directory is empty"
                return
            }

            $consent = $force
            if (!$ENV:PESTER) {
                $consent = $force -or $PSCmdlet.ShouldContinue($env:COMPUTERNAME, "Are you sure you want to uninstall Buildkit from '$path'?")
            }

            if (!$consent) {
                Write-Warning "$tool uninstallation cancelled."
                return
            }

            Write-Warning "Uninstalling preinstalled $tool at the path '$path'.`n$WhatIfMessage"
            try {
                Uninstall-BuildkitHelper -Path "$path" -Purge:$Purge
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

function Uninstall-BuildkitHelper {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Buildkit path")]
        [String]$Path,

        [parameter(HelpMessage = "Remove all program data for Buildkit")]
        [Switch] $Purge
    )

    if (Test-EmptyDirectory -Path "$Path") {
        Write-Error "Buildkit does not exist at '$Path' or the directory is empty."
        return
    }

    try {
        if (Test-ServiceRegistered -Service 'Buildkitd') {
            Stop-BuildkitdService
            Unregister-Buildkitd -BuildkitPath "$Path"
        }
    }
    catch {
        Throw "Could not stop or unregister buildkitd service. $_"
    }

    # Remove the folder where buildkit is installed and related folders
    Remove-Item -Path "$Path" -Recurse -Force

    if ($Purge) {
        Write-Output "Purging Buildkit program data"

        # Delete the buildkit key
        Write-Warning "Removing Buildkit registry key"
        Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\buildkit" -Recurse -Force -ErrorAction Ignore

        # Delete Buildkit programdata
        Write-Warning "Removing Buildkit program data"
        Uninstall-ProgramFiles "$ENV:ProgramData\Buildkit"

        # Remove from env path
        Write-Warning "Removing Buildkit from env path"
        Remove-FeatureFromPath -Feature "buildkit"
    }

    Write-Output "Successfully uninstalled buildkit."
}


function Get-ConsentToRegisterBuildkit ($path) {
    $retry = 2
    $consent = [ActionConsent]::No
    do {
        $title = "Buildkit conf file not found at $path."
        $question = "Do you want to register buildkit service without containerd cni configuration?"
        $choices = '&Yes', '&No'
        $consent = (Get-Host).UI.PromptForChoice($title, $question, $choices, 0)

        $retry --

    } while (($retry -gt 0 ) -and ($consent -eq [ActionConsent]::No))

    return $consent
}

function Test-BuildkitdServiceExists($buildkitPath) {
    $cmdRes = Get-Command -Name "buildkitd.exe" -ErrorAction Ignore
    $pathExists = Test-Path -Path "$BuildkitPath\bin\buildkitd.exe"

    return ($cmdRes -or $pathExists)
}

function Unregister-Buildkitd($buildkitPath) {
    if (!(Test-ServiceRegistered -Service 'buildkitd')) {
        Write-Warning "Buildkitd service does not exist as an installed service."
        return
    }

    # Unregister buildkit service
    $buildkitdExecutable = "$buildkitPath\bin\buildkitd.exe"

    Write-Debug "Buildkitd path: $buildkitdExecutable "
    $output = Invoke-ExecutableCommand -Executable $buildkitdExecutable -Arguments "--unregister-service"
    if ($output.ExitCode -ne 0) {
        Throw "Could not unregister buildkitd service. $($output.StandardError.ReadToEnd())"
    }
    else {
        Start-Sleep -Seconds 15
    }
}


Export-ModuleMember -Function Get-BuildkitLatestVersion
Export-ModuleMember -Function Install-Buildkit
Export-ModuleMember -Function Start-BuildkitdService -Alias Start-Buildkitd
Export-ModuleMember -Function Stop-BuildkitdService -Alias Stop-Buildkitd
Export-ModuleMember -Function Register-BuildkitdService -Alias Register-Buildkitd
Export-ModuleMember -Function Uninstall-Buildkit, Uninstall-BuildkitHelper
