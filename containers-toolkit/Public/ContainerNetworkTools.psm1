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

function Get-WinCNILatestVersion {
    param (
        [String]$repo = "microsoft/windows-container-networking"
    )
    $tool = switch ($repo.ToLower()) {
        $WINCNI_PLUGIN_REPO { "wincniplugin" }
        $CLOUDNATIVE_CNI_REPO { "cloudnativecni" }
        Default { Throw "Invalid repository. Supported repositories are $WINCNI_PLUGIN_REPO and $CLOUDNATIVE_CNI_REPO" }
    }
    $latestVersion = Get-LatestToolVersion -Tool $tool
    return $latestVersion
}

function Install-WinCNIPlugin {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [parameter(HelpMessage = "Windows CNI plugin version to use. Defaults to 'latest'")]
        [string]$WinCNIVersion = "latest",

        [parameter(HelpMessage = "Path to cni folder ~\cni (not ~\cni\bin). Defaults to `$env:ProgramFiles\containerd\cni)")]
        [String]$WinCNIPath = "$env:ProgramFiles\containerd\cni",

        [parameter(HelpMessage = "Source of the Windows CNI plugins. Defaults to 'microsoft/windows-container-networking'")]
        [ValidateSet("microsoft/windows-container-networking", "containernetworking/plugins")]
        [string]$SourceRepo = "microsoft/windows-container-networking",

        [Parameter(HelpMessage = 'OS architecture to download files for. Default is $env:PROCESSOR_ARCHITECTURE')]
        [ValidateSet('amd64', '386', "arm", "arm64")]
        [string]$OSArchitecture = $env:PROCESSOR_ARCHITECTURE,

        [Switch]
        [parameter(HelpMessage = "Installs Windows CNI plugins even if the tool already exists at the specified path")]
        $Force
    )

    begin {
        $ToolName = 'WinCNIPlugin'
        if (!$WinCNIPath) {
            $containerdPath = Get-DefaultInstallPath -Tool "containerd"
            $WinCNIPath = "$containerdPath\cni"
        }
        $WinCNIPath = $WinCNIPath -replace '(\\bin)$', ''

        # Check if WinCNI plugins are installed
        $isInstalled = -not (Test-EmptyDirectory -Path $WinCNIPath)

        $plugin = "Windows CNI plugins"

        $WhatIfMessage = "$plugin will be installed at $WINCNIPath"
        if ($isInstalled) {
            $WhatIfMessage = "$plugin will be uninstalled from and reinstalled at $WINCNIPath"
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            # Check if tool already exists at specified location
            if ($isInstalled) {
                $errMsg = "Windows CNI plugins already exists at $WinCNIPath or the directory is not empty"
                [Logger]::Warning($errMsg)

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
                $WinCNIVersion = Get-WinCNILatestVersion -Repo $SourceRepo
            }
            $WinCNIVersion = $WinCNIVersion.TrimStart('v')
            [Logger]::Info("Downloading CNI plugin version $WinCNIVersion at $WinCNIPath")

            New-Item -Path $WinCNIPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null

            [Logger]::Debug(("Downloading Windows CNI plugins from {0}" -f $SourceRepo))

            # File filter for Windows CNI plugins
            $fileFilterRegEx = $null

            if ($SourceRepo -eq "containernetworking/plugins") {
                # File filter for containernetworking/plugins
                # Contains files with .tgz extension and the checksum files with .SHA512 and .SHA256 extensions
                # We use .SHA512 files to verify the integrity of the downloaded files
                $fileFilterRegEx = ".*tgz(.SHA512)?$"
            }

            # Download file from repo
            $downloadParams = @{
                ToolName           = "$ToolName"
                Repository         = $SourceRepo
                Version            = $WinCNIVersion
                OSArchitecture     = $OSArchitecture
                DownloadPath       = "$HOME\Downloads\"
                ChecksumSchemaFile = $null
                FileFilterRegEx    = $fileFilterRegEx
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
                Feature       = "$ToolName"
                InstallPath   = "$WinCNIPath\bin"
                SourceFile    = $sourceFile
                cleanup       = $true
                UpdateEnvPath = $false
            }
            Install-RequiredFeature @params

            [Logger]::Info("CNI plugin version $WinCNIVersion ($sourceRepo) successfully installed at $WinCNIPath")
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

        [parameter(HelpMessage = "Absolute path to cni folder ~\cni (not ~\cni\bin). Defaults to `$env:ProgramFiles\containerd\cni)")]
        [String]$WinCNIPath = "$env:ProgramFiles\containerd\cni",

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
                        [Logger]::Error("NAT network initialisation cancelled.")
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

            [Logger]::Info("Creating NAT network")

            # Install missing WinCNI plugins
            if (!$isInstalled) {
                if ($force) {
                    [Logger]::Warning("Windows CNI plugins have not been installed. Installing Windows CNI plugins at '$WinCNIPath'")
                    Install-WinCNIPlugin -WinCNIPath $WinCNIPath -WinCNIVersion $WinCNIVersion -Force:$force
                }
                else {
                    [Logger]::Warning("Couldn't initialize NAT network. CNI plugins have not been installed. To install, run the command `"Install-WinCNIPlugin`".")
                    return
                }
            }

            # Check of NAT exists
            $natInfo = Get-HnsNetwork -ErrorAction Ignore | Where-Object { $_.Name -eq $networkName }
            if ($null -ne $natInfo) {
                [Logger]::Warning("$networkName already exists. To view existing networks, use `"Get-HnsNetwork`". To remove the existing network use the `"Remove-HNSNetwork`" command.")
                return
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

            [Logger]::Debug("Creating NAT network with Gateway $gateway and Subnet mask $subnet")

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

                [Logger]::Info("Successfully created new NAT network called '$($hnsNetwork.Name)' with Gateway $($hnsNetwork.Subnets.GatewayAddress), and Subnet Mask $($hnsNetwork.Subnets.AddressPrefix)")
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

        $WhatIfMessage = "Windows CNI plugins will be uninstalled from $path"
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            if (Test-EmptyDirectory -Path $path) {
                [Logger]::Info("Windows CNI plugins does not exist at $Path or the directory is empty")
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

            [Logger]::Warning("Uninstalling preinstalled Windows CNI plugin at the path $path")
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

    [Logger]::Info("Uninstalling Windows CNI plugin")
    if (Test-EmptyDirectory -Path $Path) {
        [Logger]::Error("Windows CNI plugin does not exist at $Path or the directory is empty.")
        return
    }

    # Remove the folder where WinCNI plugins are installed
    Remove-Item $Path -Recurse -Force -ErrorAction Ignore

    [Logger]::Info("Successfully uninstalled Windows CNI plugin.")
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
            # TODO: Default CNI config for containernetworking/plugins
            # https://www.cni.dev/plugins/current/main/win-bridge/
            # https://www.cni.dev/plugins/current/main/win-overlay/
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
