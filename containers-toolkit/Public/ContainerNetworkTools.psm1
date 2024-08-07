﻿###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force

function Get-WinCNILatestVersion {
    $latestVersion = Get-LatestToolVersion -Repository "microsoft/windows-container-networking"
    return $latestVersion
}

function Install-WinCNIPlugin {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [parameter(HelpMessage = "Windows CNI plugin version to use. Defaults to latest version")]
        [string]$WinCNIVersion,

        [parameter(HelpMessage = "Path to cni folder ~\cni . Not ~\cni\bin")]
        [String]$WinCNIPath,

        [Switch]
        [parameter(HelpMessage = "Installs Windows CNI plugins even if the tool already exists at the specified path")]
        $Force
    )

    begin {
        if (!$WinCNIPath) {
            $containerdPath = Get-DefaultInstallPath -Tool "containerd"
            $WinCNIPath = "$containerdPath\cni"
        }
        $WinCNIPath = $WinCNIPath -replace '(\\bin)$', ''

        # Check if Containerd is alread installed
        $isInstalled = -not (Test-EmptyDirectory -Path $WinCNIPath)

        $plugin = "Windows CNI plugins"

        $WhatIfMessage = "$plugin will be installed"
        if ($isInstalled) {
            $WhatIfMessage = "$plugin will be uninstalled and reinstalled"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($WinCNIPath, $WhatIfMessage)) {
            # Check if tool already exists at specified location
            if ($isInstalled) {
                $errMsg = "Windows CNI plugins already exists at $WinCNIPath or the directory is not empty"
                Write-Warning $errMsg

                # Uninstall if tool exists at specified location. Requires user consent
                try {
                    Uninstall-WinCNIPlugin -Path "$WinCNIPath" -Confirm:$false -Force:$Force | Out-Null
                }
                catch {
                    Throw "Windows CNI plugin installation failed. $_"
                }
            }

            # Get Windows CNI plugins version to install
            if (!$WinCNIVersion) {
                # Get default version
                $WinCNIVersion = Get-WinCNILatestVersion
            }
            $WinCNIVersion = $WinCNIVersion.TrimStart('v')
            Write-Output "Downloading CNI plugin version $WinCNIVersion at $WinCNIPath"

            New-Item -Path $WinCNIPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null

            # NOTE: We download plugins from https://github.com/microsoft/windows-container-networking
            # instead of  https://github.com/containernetworking/plugins/releases.
            # The latter causes an error in nerdctl: "networking setup error has occurred. incompatible CNI versions"

            # Download file from repo
            $cniZipFile = "windows-container-networking-cni-amd64-v${WinCNIVersion}.zip"
            $DownloadPath = "$HOME\Downloads\$cniZipFile"
            $Uri = "https://github.com/microsoft/windows-container-networking/releases/download/v$WinCNIVersion/$cniZipFile"
            $DownloadParams = @(
                @{
                    Feature      = "WinCNIPlugin"
                    Uri          = $Uri
                    Version      = $WinCNIVersion
                    DownloadPath = $DownloadPath
                }
            )
            Get-InstallationFile -Files $DownloadParams

            # Verify downloaded file checksum
            Write-OutPut "Verifying checksum for $DownloadPath"
            $checksumUri = "$Uri.sha512"
            if (-not (Test-CheckSum -DownloadedFile $DownloadPath -ChecksumUri $checksumUri)) {
                $errMsg = "Checksum verification failed for $DownloadPath"
                Write-Error $errMsg

                # Clean up downloaded file
                Write-Warning "Removing downloaded file $DownloadPath"
                Remove-Item -Path $DownloadPath -Force

                Throw $errMsg
            }

            # Expand zip file and install Win CNI plugin
            $WinCNIBin = "$WinCNIPath\bin"
            Expand-Archive -Path $DownloadPath -DestinationPath $WinCNIBin -Force
            Remove-Item -Path $DownloadPath -Force -ErrorAction Ignore

            Write-Output "Windows CNI plugin version $WinCNIVersion successfully installed at $WinCNIPath"
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Initialize-NatNetwork {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [parameter(HelpMessage = "Name of the new network. Defaults to 'nat''")]
        [String]$NetworkName = "nat",

        [parameter(HelpMessage = "Gateway IP address. Defaults to default gateway address'")]
        [String]$Gateway,

        [parameter(HelpMessage = "Size of the subnet mask. Defaults to 16")]
        [ValidateRange(0, 32)]
        [Int]$CIDR = 16,

        [parameter(HelpMessage = "Windows CNI plugins version to use. Defaults to latest version.")]
        [String]$WinCNIVersion,

        [parameter(HelpMessage = "Absolute path to cni folder ~\cni. Not ~\cni\bin")]
        [String]$WinCNIPath,

        [parameter(HelpMessage = "Bypass confirmation to install any missing dependencies (Windows CNI plugins and HNS module)")]
        [Switch] $Force
    )

    begin {
        if (!$WinCNIPath) {
            $ContainerdPath = Get-DefaultInstallPath -Tool "containerd"
            $WinCNIPath = "$ContainerdPath\cni"
        }
        $WinCNIPath = $WinCNIPath -replace '(\\bin)$', ''
        $cniConfDir = "$WinCNIPath\conf"

        # Check if WinCNI plugins is already installed
        $isInstalled = -not (Test-EmptyDirectory -Path "$WinCNIPath\bin")

        $WhatIfMessage = "Initialises a NAT network using Windows CNI plugins installed"
        if (!$isInstalled) {
            $WhatIfMessage = "`n`t1. Import `"HostNetworkingService`" or `"HNS`" module,`n`t2. Install Windows CNI plugins, and 3. Initialize a NAT network using Windows CNI plugins installed`n"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            if (!$force) {
                if (!$ENV:PESTER) {
                    if (-not $PSCmdlet.ShouldContinue('', "Are you sure you want to initialises a NAT network?`n`t`tHNS module will be imported and missing dependencies (Windows CNI Plugins) will be installed if missing.")) {
                        Write-Error "NAT network initialisation cancelled."
                        return
                    }
                }
            }

            # Import HNS module
            try {
                Import-HNSModule -Force:$Force
            }
            catch {
                Throw "Could not import HNS module. $_"
            }

            # Check of NAT exists
            $natInfo = Get-HnsNetwork -ErrorAction Ignore | Where-Object { $_.Name -eq $networkName }
            if ($null -ne $natInfo) {
                Write-Warning "$networkName already exists. To view existing networks, use `"Get-HnsNetwork`". To remove the existing network use the `"Remove-HNSNetwork`" command."
                return
            }

            Write-Information -MessageData "Creating NAT network" -InformationAction Continue

            # Install missing WinCNI plugins
            if (!$isInstalled) {
                Install-MissingPlugin -WinCNIVersion $WinCNIVersion -Force:$Force
            }

            New-Item -ItemType 'Directory' -Path $cniConfDir -Force | Out-Null

            # Check if `New-HNSNetwork` command exists
            if (-not (Get-Command -Name 'New-HNSNetwork' -ErrorAction SilentlyContinue)) {
                Throw "`"New-HNSNetwork`" command does not exist. Ensure the HNS module is installed. To resolve this issue, see`n`thttps://github.com/microsoft/containers-toolkit/blob/main/docs/FAQs.md#2-new-hnsnetwork-command-does-not-exist"
            }

            # Set default gateway if gateway us null and generate subnet mash=k from Gateway
            if (!$gateway) {
                $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0").NextHop
            }
            $networkIdentifier = $gateway -replace "\.\d*$", ".0"
            $subnet = "$networkIdentifier/$CIDR"

            Write-Debug "Creating NAT network with Gateway $gateway and Subnet mask $subnet"

            # Set default WinCNI version of null
            if (!$WinCNIVersion) {
                # Get default version
                $WinCNIVersion = Get-WinCNILatestVersion
            }
            $WinCNIVersion = $WinCNIVersion.TrimStart('v')

            try {
                # Restart HNS service
                Get-Service "hns" -ErrorAction SilentlyContinue | Restart-Service -Force -ErrorAction SilentlyContinue

                # Create NAT network
                $hnsNetwork = New-HNSNetwork -Name $networkName -Type NAT -AddressPrefix $subnet -Gateway $gateway

                # Set default CNI config
                $params = @{
                    WinCNIVersion = $WinCNIVersion
                    NetworkName   = $networkName
                    Gateway       = $gateway
                    Subnet        = $subnet
                    CNIConfDir    = $cniConfDir
                }
                Set-DefaultCNIConfig @params

                Write-Output "Successfully created new NAT network called '$($hnsNetwork.Name)' with Gateway $($hnsNetwork.Subnets.GatewayAddress), and Subnet Mask $($hnsNetwork.Subnets.AddressPrefix)"
            }
            catch {
                Throw "Could not create a new NAT network $networkName with Gateway $gateway and Subnet mask $subnet. $_"
            }
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function/script
            return
        }
    }
}

function Uninstall-WinCNIPlugin {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [parameter(HelpMessage = "Windows CNI plugin path")]
        [String]$Path,

        [parameter(HelpMessage = "Bypass confirmation to uninstall Windows CNI plugins")]
        [Switch] $Force
    )

    begin {
        $tool = 'WinCNIPlugin'

        if (!$Path) {
            $ContainerdPath = Get-DefaultInstallPath -Tool "containerd"
            $Path = "$ContainerdPath\cni"
        }

        $Path = $Path -replace '(\\bin\\?)$', ''

        $WhatIfMessage = "Windows CNI plugins will be uninstalled"
    }

    process {
        if ($PSCmdlet.ShouldProcess($Path, $WhatIfMessage)) {
            if (Test-EmptyDirectory -Path $path) {
                Write-Output "Windows CNI plugins does not exist at $Path or the directory is empty"
                return
            }

            # Check user consents to uninstall WinCNIPlugin
            $consent = $force
            if (!$ENV:PESTER) {
                $consent = $force -or $PSCmdlet.ShouldContinue($Path, 'Are you sure you want to uninstall Windows CNI plugins?')
            }

            if (!$consent) {
                Throw "Windows CNI plugins uninstallation cancelled."
            }

            Write-Warning "Uninstalling preinstalled Windows CNI plugin at the path $path"
            try {
                Uninstall-WinCNIPluginHelper -Path $path
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

function Uninstall-WinCNIPluginHelper {
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Windows CNI plugin path")]
        [String]$Path
    )

    Write-Output "Uninstalling Windows CNI plugin"
    if (Test-EmptyDirectory -Path $Path) {
        Write-Error "Windows CNI plugin does not exist at $Path or the directory is empty."
        return
    }

    # Remove the folder where WinCNI plugins are installed
    Remove-Item $Path -Recurse -Force -ErrorAction Ignore

    Write-Output "Successfully uninstalled Windows CNI plugin."
}

function Import-HNSModule {
    param(
        [Switch] $Force
    )

    $ModuleName = 'HostNetworkingService'
    # https://learn.microsoft.com/en-us/powershell/module/hostnetworkingservice/?view=windowsserver2025-ps
    if ((Get-Module -Name $ModuleName)) {
        return
    }

    $ModuleName = 'HNS'
    # https://www.powershellgallery.com/packages/HNS/0.2.4
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Import-Module -Name $ModuleName -DisableNameChecking -Force:$Force
        return
    }

    # Throw an error if the module is not installed
    Throw "`"HostNetworkingService`" or `"HNS`" module is not installed. To resolve this issue, see`n`thttps://github.com/microsoft/containers-toolkit/blob/main/docs/FAQs.md#2-new-hnsnetwork-command-does-not-exist"
}

function Install-MissingPlugin {
    param(
        [parameter(HelpMessage = "Windows CNI plugin version to use. Defaults to latest version")]
        [string]$WinCNIVersion,

        [Switch]$Force
    )
    # Get user consent to install missing dependencies
    $consent = $Force
    if (!$Force) {
        $title = "Windows CNI plugins have not been installed."
        $question = "Do you want to install the Windows CNI plugins?"
        $choices = '&Yes', '&No'
        $consent = ([ActionConsent](Get-Host).UI.PromptForChoice($title, $question, $choices, 1)) -eq [ActionConsent]::Yes

        if (-not $consent) {
            $downloadPath = "https://github.com/microsoft/windows-container-networking"
            Throw "Windows CNI plugins have not been installed. To install, run the command `"Install-WinCNIPlugin`" or download from $downloadPath."
        }
    }

    Install-WinCNIPlugin -WinCNIVersion $WinCNIVersion -Force:$consent
}


# FIXME: nerdctl- Warning when user tries to run container with this network config
function Set-DefaultCNIConfig {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Low'
    )]
    param(
        [String]$WinCNIVersion,
        [String]$networkName,
        [String]$gateway,
        [String]$subnet,
        [String]$cniConfDir
    )

    process {
        if ($PSCmdlet.ShouldProcess('', "Sets Default CNI config")) {
            # CurrentEndpointCount   : 1
            # MaxConcurrentEndpoints : 1
            # TotalEndpoints
            $CNIConfig = @"
{
"cniVersion": "$WinCNIVersion",
"name": "$networkName",
"type": "nat",
"master": "Ethernet",
"ipam": {
    "subnet": "$subnet",
    "routes": [
        {
            "gateway": "$gateway"
        }
    ]
},
"capabilities": {
    "portMappings": true,
    "dns": true
    }
}
"@
            $CNIConfig | Set-Content "$cniConfDir\0-containerd-nat.conf" -Force
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

Export-ModuleMember -Function Get-WinCNILatestVersion
Export-ModuleMember -Function Install-WinCNIPlugin
Export-ModuleMember -Function Uninstall-WinCNIPlugin, Uninstall-WinCNIPluginHelper
Export-ModuleMember -Function Initialize-NatNetwork
