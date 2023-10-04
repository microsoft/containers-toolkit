function Install-WinCNIPlugin {
    param(
        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Windows CNI plugin version to use")]
        $WinCNIVersion = "0.3.0",

        [String]
        [parameter(HelpMessage = "Path to cni folder ~\cni . Not ~\cni\bin")]
        $WinCNIPath
    )

    $ContainerdPath = "$Env:ProgramFiles\containerd"
    if ($null -eq $WinCNIPath) {
        $WinCNIPath = "$ContainerdPath\cni"
    }

    $WinCNIBin = "$WinCNIPath\bin"

    $cniZipFile = "windows-container-networking-cni-amd64-v${WinCNIVersion}.zip"

    Write-Information -InformationAction Continue "Configuring container networking"

    # TODO: REsearch on which CNI plugin to use
    # https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-windows-amd64-v1.3.0.tgz

    $Uri = "https://github.com/microsoft/windows-container-networking/releases/download/v$WinCNIVersion/$cniZipFile"
    Write-Information -InformationAction Continue -MessageData "Downloading CNI plugin version ${Version}"

    try {
        Invoke-WebRequest -Uri $Uri -OutFile $ContainerdPath\$cniZipFile
    }
    catch {
        Write-Error "Could not download file $Uri. $Error"
        exit
    }

    Expand-Archive -Path $ContainerdPath\$cniZipFile -DestinationPath $WinCNIBin -Force
    Remove-Item -Path $ContainerdPath\$cniZipFile -Force -ErrorAction SilentlyContinue
}

function Initialize-NatNetwork {
    param(
        [String]
        [parameter(HelpMessage = "Absolute path to cni folder ~\cni. Not ~\cni\bin")]
        $WinCNIPath
    )

    $ContainerdPath = "$Env:ProgramFiles\containerd"
    if ($null -eq $WinCNIPath) {
        $WinCNIPath = "$ContainerdPath\cni"
    }

    $cniConfPath = "$WinCNIPath/conf"
    if (!(Test-Path $cniConfPath)) { 
        New-Item -ItemType Directory -Force -Path $cniConfPath | Out-Null 
    }

    try {
        # https://www.powershellgallery.com/packages/HNS/0.2.4
        if ($null -eq (Get-Command -Name *hns*)) {
            Install-Module -Name HNS
        }
    }
    catch {
        if (!Test-Path("$cniConfPath/hns.psm1")) {
            $Uri = "https://raw.githubusercontent.com/microsoft/SDN/master/Kubernetes/windows/hns.psm1"
            Invoke-WebRequest -Uri $Uri -OutFile $cniConfPath/hns.psm1

            try {
                Invoke-WebRequest -Uri $Uri -OutFile $cniConfPath/hns.psm1
            }
            catch {
                Write-Error "Could not download file $Uri. $_"
                exit
            }
        }
        Import-Module $cniConfPath/hns.psm1
    }

    # Check of NAT exists
    $natInfo = Get-HnsNetwork -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "nat" }

    # Creating a nat network
    # https://github.com/containerd/containerd/blob/main/script/setup/install-cni-windows
    if ($null -eq $natInfo) {
        Write-Information "Creating a NAT network"

        $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0").NextHop
        $subnet = "$gateway/16"

        $gateway
        $subnet

        $CNIConfig = @{
            "cniVersion"   = "$WinCNIVersion"
            "name"         = "nat"
            "type"         = "nat"
            "master"       = "Ethernet"
            "ipam"         = @{
                "subnet" = "$subnet"
                "routes" = @(
                    @{
                        "gateway" = "$gateway"
                    }
                )
            }
            "capabilities" = @{
                "portMappings" = $true
                "dns"          = $true
            }
        } | ConvertTo-Json

        # FIXME: Does not work on Windows VM
        try {
            New-HNSNetwork -Name "nat" -Type NAT -AddressPrefix $subnet -Gateway $gateway -Verbose
            $CNIConfig | Set-Content "$cniConfPath\0-containerd-nat.conf" -Force
        }
        catch {
            Write-Error "Could not create a new NAT network. $_"
        }
    }
}


Export-ModuleMember -Function Install-WinCNIPlugin
Export-ModuleMember -Function Initialize-NatNetwork
