$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\SetupUtilities.psm1" -Force

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

    # Uninstall if tool exists at specified location. Requires user consent
    Uninstall-ContainerTool -Tool "WinCNIPlugin" -Path $WinCNIPath

    if (!$WinCNIVersion) {
        # Get default version
        $WinCNIVersion = Get-WinCNILatestVersion
    }
    $WinCNIVersion = $WinCNIVersion.TrimStart('v')
    Write-Output "Downloading CNI plugin version $WinCNIVersion at $WinCNIPath"

    $parentPath = Split-Path -Parent $WinCNIPath
    New-Item -Path $parentPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

    # NOTE: We download plugins from instead of  https://github.com/containernetworking/plugins/releases.
    # The latter causes an error in Nerdctl: "networking setup error has occurred. incompatible CNI versions"
    
    # Download file from repo
    $cniZipFile = "windows-container-networking-cni-amd64-v${WinCNIVersion}.zip"
    $Uri = "https://github.com/microsoft/windows-container-networking/releases/download/v$WinCNIVersion/$cniZipFile"
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $parentPath\$cniZipFile
    }
    catch {
        Throw "Could not download file $Uri. $_"
    }

    # Expand zip file and install Win CNI plugin
    $WinCNIBin = "$WinCNIPath\bin"
    Expand-Archive -Path $parentPath\$cniZipFile -DestinationPath $WinCNIBin -Force
    Remove-Item -Path $parentPath\$cniZipFile -Force -ErrorAction SilentlyContinue

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

    $WinCNIPath = $WinCNIPath.TrimEnd('\bin')
    if (!$WinCNIPath) {
        $ContainerdPath = Get-DefaultInstallPath -Tool "containerd"
        $WinCNIPath = "$ContainerdPath\cni"
    }

    $cniConfDir = "$WinCNIPath\conf"

    # Install missing WinCNI plugins
    if (!(Get-ChildItem -Path "$WinCNIPath\bin")) {
        Install-MissingPlugin -WinCNIVersion $WinCNIVersion
    }

    if (!(Test-Path $cniConfDir)) { 
        New-Item -ItemType 'Directory' -Path $cniConfDir -Force | Out-Null 
    }

    # Import HNS module
    Import-HNSModule

    # Check of NAT exists
    $natInfo = Get-HnsNetwork -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $networkName }
    if ($null -ne $natInfo) {
        Write-Error "$networkName already exists. To remove the existing network use the `Remove-HNSNetwork` command "
        $natInfo | Select-Object Name, ID, Type, `
            @{l = "Gateway"; e = { $_.Subnets.GatewayAddress } }, `
            @{l = "Subnet Mask"; e = { $_.Subnets.AddressPrefix } }
        return
    }

    # Set default gateway if gateway us null and generate subnet mash=k from Gateway
    if (!$gateway) {
        $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0").NextHop
    }
    $gateway -match '\.\d*$' | Out-Null; $networkIdentifier = $gateway.TrimEnd($Matches[0]) + ".0"
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
        Write-Error "Could not create a new NAT network $networkName with Gateway $gateway and Subnet mask $subnet. $_"
    }
}

# NEEDSDOC: Update help documentation
function Uninstall-WinCNIPlugin {
    param(
        [parameter(HelpMessage = "Windows CNI plugin path")]
        [String]$Path
    )

    if (!$Path) {
        $ContainerdPath = Get-DefaultInstallPath -Tool "containerd"
        $Path = "$ContainerdPath\cni"
    }
    
    Write-Output "Uninstalling Windows CNI plugin"
    $pathItems = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
    if (!$pathItems.Name.Length) {
        Write-Error "Windows CNI plugin does not exist at $Path or the directory is empty"
        return
    }

    # Remove the folder where nerdctl was installed
    Get-Item -Path $Path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    Write-Output "Successfully uninstalled Windows CNI plugin."
}

function Import-HNSModule {
    try {
        # https://www.powershellgallery.com/packages/HNS/0.2.4
        if ($null -eq (Get-Command -Name "*HNS*" -ErrorAction SilentlyContinue | Where-Object { $_.Source -eq "HNS" })) {
            Install-Module -Name HNS -Scope CurrentUser -AllowClobber -Force
        }

        if ($null -eq (Get-Module -Name HNS -ErrorAction SilentlyContinue)) {
            Import-Module -Name HNS -Force
        }
    }
    catch [System.IO.FileNotFoundException] {
        Throw "Could not import HNS module. $_"
    }
    catch {
        $path = "$Env:ProgramFiles\containerd\cni\hns.psm1"
        if (!(Test-Path -Path $path)) {
            $Uri = "https://raw.githubusercontent.com/microsoft/SDN/master/Kubernetes/windows/hns.psm1"
            try {
                Invoke-WebRequest -Uri $Uri -OutFile $path
            }
            catch {
                Throw "Could not download HNS module from $Uri. $_"
            }
        }

        try {
            if ($null -eq (Get-Module -Name HNS -ErrorAction SilentlyContinue)) {
                Import-Module $path -Force
            }
        }
        catch {
            Throw "Could not import HNS module. $_"
        }
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
    $consent = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    switch ([ActionConsent]$consent) {
        [ActionConsent]::Yes { Install-WinCNIPlugin -WinCNIVersion $WinCNIVersion }
        Default {
            $downloadPath = "https://github.com/microsoft/windows-container-networking"
            Throw "Windows CNI plugins have not been installed. To install, run the command `Install-WinCNIPlugin` or download from $downloadPath, then rerun this command"
        }
    }
}


# FIXME: Causes error when user tries to run container with this network config
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
Export-ModuleMember -Function Uninstall-WinCNIPlugin
Export-ModuleMember -Function Initialize-NatNetwork
