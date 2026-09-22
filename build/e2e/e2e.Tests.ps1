Describe "Containers Toolkit E2E Module Tests" {
    BeforeAll {
        # Setup

        # # Load Newtonsoft.Json.dll only if Test-Json is not available
        # if (-not(Get-Command -Name "Test-Json" -ErrorAction SilentlyContinue)) {
        #     Write-Debug "Loading Newtonsoft.Json assemblies..."
        #     $loadAssembliesScript = Join-Path "$BUILD_DIR" "hacks/Load-NewtonsoftDlls.ps1"
        #     & $loadAssembliesScript
        # }

        # Install the HNS module
        Write-Debug "Installing HNS module..."
        New-Item -Path "$ENV:HNS_MODULE_DIR" -ItemType Directory -Force | Out-Null
        $hnsUri = 'https://raw.githubusercontent.com/microsoft/SDN/refs/heads/master/Kubernetes/windows/hns.v2.psm1'
        Invoke-WebRequest -Uri $hnsUri -OutFile "$ENV:HNS_MODULE_DIR/hns.psm1"
        $env:PSModulePath += ";$ENV:HNS_MODULE_DIR"

        # Import the Containers-Toolkit module
        Write-Debug "Importing $ENV:CTK_MODULE_NAME module..."
        Import-Module -Name "$ManifestPath" -Force -ErrorAction Stop
    }

    It "Should import the HNS module" {
        Get-Module -ListAvailable -Name "HNS" | Should -Not -BeNullOrEmpty
    }

    It "Should import the Containers Toolkit module" {
        Get-Module -Name $ENV:CTK_MODULE_NAME | Should -Not -BeNullOrEmpty
    }

    Context "Install container tools" -Tag "Install" {
        BeforeAll {
            Install-Containerd -Setup -Force -Confirm:$false
            Install-Buildkit -Setup -Force -Confirm:$false
            Install-Nerdctl -Force -Confirm:$false
            Initialize-NatNetwork -Gateway 192.168.0.1 -Force -Confirm:$false
        }
        It "Should install and register container tools" {
            $uninstalledTools = Show-ContainerTools -Latest | Where-Object { $_.Installed -eq $false }
            $uninstalledTools | Should -BeNullOrEmpty
        }

        It "Should register containerd service" {
            Get-Service -Name containerd -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }

        It "Should register buildkitd service" {
            Get-Service -Name buildkitd -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }

        It "Should create a NAT network" {
            $hnsNetwork = Get-HnsNetwork | Where-Object { $_.Name -eq "Nat" }
            $hnsNetwork | Should -Not -BeNullOrEmpty
        }

        It "Should setup CNI" {
            $cniConfig = Join-Path -Path $env:ProgramFiles -ChildPath "containerd\config.toml"
            $cniConfig | Should -Exist

            $cniBin = Join-Path -Path $env:ProgramFiles -ChildPath "containerd\cni\bin"
            $binaries = Get-ChildItem -Path $cniBin -Filter "*.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

            $cniConfig | Should -Exist
            $binaries | Should -Not -BeNullOrEmpty
            $binaries | Should -Be @('nat.exe', 'sdnbridge.exe', 'sdnoverlay.exe')
        }
    }

    Context "Reinstall container tools" -Tag "Reinstall" {
        BeforeAll {
            # Ensure all tools are installed before attempting to uninstall
            if (-not (Get-Command -Name "containerd" -ErrorAction SilentlyContinue)) {
                Write-Debug "Installing container tools before uninstalling."
                Install-Containerd -Setup -Force -Confirm:$false
            }
            if (-not (Get-Command -Name "buildkitd" -ErrorAction SilentlyContinue)) {
                Write-Debug "Installing buildkit before uninstalling."
                Install-Buildkit -Setup -Force -Confirm:$false
            }
            if (-not (Get-Command -Name "nerdctl" -ErrorAction SilentlyContinue)) {
                Write-Debug "Installing nerdctl before uninstalling."
                Install-Nerdctl -Force -Confirm:$false
            }
        }

        It "Should reinstall all tools and register services" {
            { Install-Containerd -Force -Confirm:$false } | Should -Not -Throw
            { Install-Buildkit -Force -Confirm:$false } | Should -Not -Throw
            { Install-Nerdctl -Force -Confirm:$false } | Should -Not -Throw

            $tools = @("containerd", "buildctl", "nerdctl")
            foreach ($tool in $tools) {
                $command = Get-Command -Name $tool -ErrorAction Stop
                $command | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Uninstall container tools" -Tag "Uninstall" {
        BeforeAll {
            # Ensure all tools are installed before attempting to uninstall
            if (-not (Get-Command -Name "containerd" -ErrorAction SilentlyContinue)) {
                Write-Debug "Installing container tools before uninstalling."
                Install-Containerd -Setup -Force -Confirm:$false
            }
            if (-not (Get-Command -Name "buildkitd" -ErrorAction SilentlyContinue)) {
                Write-Debug "Installing buildkit before uninstalling."
                Install-Buildkit -Setup -Force -Confirm:$false
            }
            if (-not (Get-Command -Name "nerdctl" -ErrorAction SilentlyContinue)) {
                Write-Debug "Installing nerdctl before uninstalling."
                Install-Nerdctl -Force -Confirm:$false
            }
        }

        It "Should uninstall all tools and unregister services" {
            Uninstall-Containerd -Force -Confirm:$false
            Uninstall-Buildkit -Force -Confirm:$false
            Uninstall-Nerdctl -Force -Confirm:$false

            $tools = @("containerd", "buildkit", "nerdctl")
            foreach ($tool in $tools) {
                $retryCount = 3
                do {
                    $command = Get-Command -Name $tool -ErrorAction SilentlyContinue |
                    Where-Object { $_.Source -like "$env:programfiles\*" }
                    if (-not $command) { break }
                    Start-Sleep -Seconds 5
                    $retryCount--
                } while ($retryCount -gt 0)

                $command | Should -BeNullOrEmpty
            }

            $services = @("containerd", "buildkitd")
            foreach ($svc in $services) {
                $retryCount = 3
                do {
                    $svcObj = Get-Service -Name $svc -ErrorAction SilentlyContinue
                    if (-not $svcObj) { break }
                    Start-Sleep -Seconds 5
                    $retryCount--
                } while ($retryCount -gt 0)

                $svcObj | Should -BeNullOrEmpty
            }
        }
    }
}
