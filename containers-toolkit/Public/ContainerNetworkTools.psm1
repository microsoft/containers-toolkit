###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\CommonToolUtilities.psm1" -Force

# $ErrorActionPreference = 'Stop'

function Get-WinCNILatestVersion {
    $latestVersion = Get-LatestToolVersion -Repository "microsoft/windows-container-networking"
    return $latestVersion
}

function Install-WinCNIPlugin {
    param(
        [parameter(HelpMessage = "Windows CNI plugin version to use. Defaults to latest version")]
        [string]$WinCNIVersion,

        [parameter(HelpMessage = "Path to cni folder ~\cni . Not ~\cni\bin")]
        [String]$WinCNIPath
    )

    if (!$WinCNIPath) {
        $containerdPath = Get-DefaultInstallPath -Tool "containerd"
        $WinCNIPath = "$containerdPath\cni"
    }
    $WinCNIPath = $WinCNIPath -replace '(\\bin)$', ''

    if (!(Test-EmptyDirectory -Path $WinCNIPath)) {
        Write-Warning "Windows CNI plugin already exists at $WinCNIPath or the directory is not empty"
    }

    # Uninstall if tool exists at specified location. Requires user consent
    try {
        Uninstall-WinCNIPlugin -Path $WinCNIPath | Out-Null
    }
    catch {
        Throw "Windows CNI plugin installation cancelled. $_"
    }

    if (!$WinCNIVersion) {
        # Get default version
        $WinCNIVersion = Get-WinCNILatestVersion
    }
    $WinCNIVersion = $WinCNIVersion.TrimStart('v')
    Write-Output "Downloading CNI plugin version $WinCNIVersion at $WinCNIPath"

    New-Item -Path $WinCNIPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null

    # NOTE: We download plugins from instead of  https://github.com/containernetworking/plugins/releases.
    # The latter causes an error in Nerdctl: "networking setup error has occurred. incompatible CNI versions"

    # Download file from repo
    $cniZipFile = "windows-container-networking-cni-amd64-v${WinCNIVersion}.zip"
    $DownloadPath = "$HOME\Downloads\$cniZipFile"
    $DownloadParams = @(
        @{
            Feature      = "WinCNIPlugin"
            Uri          = "https://github.com/microsoft/windows-container-networking/releases/download/v$WinCNIVersion/$cniZipFile"
            Version      = $WinCNIVersion
            DownloadPath = $DownloadPath
        }
    )
    Get-InstallationFiles -Files $DownloadParams

    # Expand zip file and install Win CNI plugin
    $WinCNIBin = "$WinCNIPath\bin"
    Expand-Archive -Path $DownloadPath -DestinationPath $WinCNIBin -Force
    Remove-Item -Path $DownloadPath -Force -ErrorAction Ignore

    Write-Output "Windows CNI plugin version $WinCNIVersion successfully installed at $WinCNIPath"
}

function Initialize-NatNetwork {
    param(
        [parameter(HelpMessage = "Name of the new network. Defaults to 'nat''")]
        [String]$NetworkName = "nat",

        [parameter(HelpMessage = "Gateway IP address. Defaults to default gateway address'")]
        [String]$Gateway,

        [parameter(HelpMessage = "Size of the subnet mask. Defaults to 16")]
        [ValidateRange(0, 32)]
        [Int]$CIDR = 16,

        [parameter(HelpMessage = "Windows CNI plugin version to use. Defaults to latest version.")]
        [String]$WinCNIVersion,

        [parameter(HelpMessage = "Absolute path to cni folder ~\cni. Not ~\cni\bin")]
        [String]$WinCNIPath
    )

    Write-Information "Creating NAT network"

    if (!$WinCNIPath) {
        $ContainerdPath = Get-DefaultInstallPath -Tool "containerd"
        $WinCNIPath = "$ContainerdPath\cni"
    }
    $WinCNIPath = $WinCNIPath -replace '(\\bin)$', ''
    $cniConfDir = "$WinCNIPath\conf"

    # Install missing WinCNI plugins
    if (Test-EmptyDirectory -Path "$WinCNIPath\bin") {
        Install-MissingPlugin -WinCNIVersion $WinCNIVersion
    }

    New-Item -ItemType 'Directory' -Path $cniConfDir -Force | Out-Null

    # Import HNS module
    try {
        Import-HNSModule
    }
    catch {
        Throw "Could not import HNS module. $_"
    }

    # Check of NAT exists
    $natInfo = Get-HnsNetwork -ErrorAction Ignore | Where-Object { $_.Name -eq $networkName }
    if ($null -ne $natInfo) {
        Throw "$networkName already exists. To view existing networks, use `Get-HnsNetwork`. To remove the existing network use the `Remove-HNSNetwork` command."
    }

    # Set default gateway if gateway us null and generate subnet mash=k from Gateway
    if (!$gateway) {
        $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0").NextHop
    }
    $networkIdentifier = $gateway -replace "\.\d*$", ".0"
    $subnet = "$networkIdentifier/$CIDR"

    # Set default WinCNI version of null
    if (!$WinCNIVersion) {
        # Get default version
        $WinCNIVersion = Get-WinCNILatestVersion
    }
    $WinCNIVersion = $WinCNIVersion.TrimStart('v')

    try {
        $hnsNetwork = New-HNSNetwork -Name $networkName -Type NAT -AddressPrefix $subnet -Gateway $gateway

        $params = @{
            WinCNIVersion = $WinCNIVersion
            NetworkName   = $networkName
            Gateway       = $gateway
            Subnet        = $subnet
            CNIConfDir    = $cniConfDir
        }
        Set-DefaultCNICInfig @params

        Write-Output "Successfully created new NAT network called '$($hnsNetwork.Name)' with Gateway $($hnsNetwork.Subnets.GatewayAddress), and Subnet Mask $($hnsNetwork.Subnets.AddressPrefix)"
    }
    catch {
        Throw "Could not create a new NAT network $networkName with Gateway $gateway and Subnet mask $subnet. $_"
    }
}

function Uninstall-WinCNIPlugin {
    param(
        [parameter(HelpMessage = "Windows CNI plugin path")]
        [String]$Path
    )

    if (!$Path) {
        $ContainerdPath = Get-DefaultInstallPath -Tool "containerd"
        $Path = "$ContainerdPath\cni"
    }

    $Path = $Path -replace '(\\bin\\?)$', ''
    if (Test-EmptyDirectory -Path $path) {
        Write-Output "Windows CNI plugin does not exist at $Path or the directory is empty"
        return
    }

    $tool = 'WinCNIPlugin'
    $consent = Uninstall-ContainerToolConsent -Tool $tool -Path $Path
    if ($consent) {
        Write-Warning "Uninstalling preinstalled Windows CNI plugin at the path $path"
        try {
            Uninstall-WinCNIPluginHelper -Path $path
        }
        catch {
            Throw "Could not uninstall $tool. $_"
        }
    }
    else{
        Throw "Windows CNI plugin uninstallation cancelled."
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
    try {
        # https://www.powershellgallery.com/packages/HNS/0.2.4
        if ($null -eq ( Get-Module -ListAvailable -Name 'HNS')) {
            Install-Module -Name HNS -Scope CurrentUser -AllowClobber -Force
        }

        Import-Module -Name HNS -DisableNameChecking -Force
    }
    catch {
        $WinCNIPath = "$Env:ProgramFiles\containerd\cni"
        $path = "$WinCNIPath\hns.psm1"
        if (!(Test-Path -Path $path)) {
            $DownloadParams = @(
                @{
                    Feature      = "HNS.psm1"
                    Uri          = 'https://raw.githubusercontent.com/microsoft/SDN/master/Kubernetes/windows/hns.psm1'
                    DownloadPath = $WinCNIPath
                }
            )
            Get-InstallationFiles -Files $DownloadParams
        }

        Import-Module $path -DisableNameChecking -Force
    }
}

function Install-MissingPlugin {
    param(
        [parameter(HelpMessage = "Windows CNI plugin version to use. Defaults to latest version")]
        [string]$WinCNIVersion
    )

    $title = "Windows CNI plugins have not been installed."
    $question = "Do you want to install the Windows CNI plugins?"
    $choices = '&Yes', '&No'
    $consent = (Get-Host).UI.PromptForChoice($title, $question, $choices, 1)
    switch ([ActionConsent]$consent) {
        ([ActionConsent]::Yes) {
            Install-WinCNIPlugin -WinCNIVersion $WinCNIVersion
        }
        Default {
            $downloadPath = "https://github.com/microsoft/windows-container-networking"
            Throw "Windows CNI plugins have not been installed. To install, run the command `Install-WinCNIPlugin` or download from $downloadPath, then rerun this command"
        }
    }
}


# FIXME: Nerdctl- Warning when user tries to run container with this network config
function Set-DefaultCNICInfig ($WinCNIVersion, $networkName, $gateway, $subnet, $cniConfDir) {
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


Export-ModuleMember -Function Get-WinCNILatestVersion
Export-ModuleMember -Function Install-WinCNIPlugin
Export-ModuleMember -Function Uninstall-WinCNIPlugin, Uninstall-WinCNIPluginHelper
Export-ModuleMember -Function Initialize-NatNetwork
