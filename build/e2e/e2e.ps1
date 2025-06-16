<#
.SYNOPSIS
Runs Containers Toolkit end-to-end tests on Windows.


.PARAMETER ManifestPath
Path to the Containers Toolkit manifest file (PSD1) to import the module.

#>

[CmdletBinding()]
param (
    [Parameter(HelpMessage = "Verbosity of output. Default: 'Detailed'")]
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string] $Verbosity = 'Normal',

    [Parameter(HelpMessage = "Run tests for specific commands/functions")]
    [string] $Tag
)

$ErrorActionPreference = 'Stop'

$E2E_DIR = $PSScriptRoot
$BUILD_DIR = Split-Path -Parent -Path $E2E_DIR
$ROOT_DIR = Split-Path -Parent -Path $BUILD_DIR
$MODULE_DIR = Join-Path -Path $ROOT_DIR -ChildPath "containers-toolkit"


# Define environment variables
$ENV:CTK_MODULE_NAME = "Containers-Toolkit"
$ENV:HNS_MODULE_DIR = "$env:USERPROFILE\HNS"

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator." -ErrorAction Stop
}

# Get .Net Version
Write-Host "System version: $([System.Environment]::Version)"
Write-Host "Checking .NET version..." -ForegroundColor Cyan
Write-Output (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full')

# Get PS Version
Write-Host "PowerShell version:" -ForegroundColor Cyan
$PSVersionTable | Format-Table -AutoSize

# # Get OS Info
# Write-Host "Operating System Information:" -ForegroundColor Cyan
# $regInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
#     Select-Object ProductName, ReleaseId, CurrentBuild, DisplayVersion
# $osVersion = [PSCustomObject]@{
#     OSVersion = [System.Environment]::OSVersion.Version
# }
# $compInfo = Get-ComputerInfo | Select-Object `
#     @{l = 'WindowsProductName'; e = { $_.WindowsProductName } }, `
#     @{l = 'OsArchitecture'; e = { $_.OsArchitecture } }, `
#     @{l = 'WindowsBuildLabEx'; e = { $_.WindowsBuildLabEx } }
# $osInfo = [PSCustomObject]@{
#     ProductName        = $regInfo.ProductName
#     ReleaseId          = $regInfo.ReleaseId
#     DisplayVersion     = $regInfo.DisplayVersion
#     OSVersion          = $osVersion.OSVersion
#     WindowsProductName = $compInfo.WindowsProductName
#     OsArchitecture     = $compInfo.OsArchitecture
#     WindowsBuildLabEx  = $compInfo.WindowsBuildLabEx
# }
# Write-Output $osInfo

# Unblock all files in the module directory
Write-Debug "Unblocking files in the module directory..."
$ManifestPath = Join-Path -Path $MODULE_DIR -ChildPath "containers-toolkit.psd1"
$modulePath = Split-Path -Path $ManifestPath -Parent
Get-ChildItem -Path $modulePath -Recurse | Unblock-File





#######################################################
################ PESTER CONFIGURATION #################
#######################################################
# https://pester.dev/docs/commands/New-PesterConfiguration
Import-Module Pester -Force
$config = [PesterConfiguration]::Default
$config.Output.Verbosity = $Verbosity
$config.Filter.Tag = ($tag -split ',')
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = "NUnitXML"
$config.TestResult.OutputPath = "$ROOT_DIR\TestResults\E2E--Test-Results.xml"
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.OutputFormat = "JaCoCo"
$config.CodeCoverage.OutputPath = "$ROOT_DIR\TestResults\e2e-coverage.xml"
$config.CodeCoverage.CoveragePercentTarget = 60
$config.CodeCoverage.Path = @( "$MODULE_DIR\Private", "$MODULE_DIR\Public" )
$config.Run.Path = "$E2E_DIR"
$config.Run.Exit = $False
$config.Run.SkipRemainingOnFailure = 'Run'
$config.Should.ErrorAction = 'Stop'
# $config.Run.Container = $array

Invoke-Pester -Configuration $config



# # Load Newtonsoft.Json.dll only if Test-Json is not available
# if (-not(Get-Command -Name "Test-Json" -ErrorAction SilentlyContinue)) {
#     Write-Debug "Loading Newtonsoft.Json assemblies..."
#     $loadAssembliesScript = Join-Path "$BUILD_DIR" "hacks/Load-NewtonsoftDlls.ps1"
#     & $loadAssembliesScript
# }

# # Install HNS module
# Write-Debug "Installing HNS module..."
# $hnsDir = "$env:USERPROFILE\HNS"
# New-Item -Path $hnsDir -ItemType Directory -Force | Out-Null
# $Uri = 'https://raw.githubusercontent.com/microsoft/SDN/refs/heads/master/Kubernetes/windows/hns.v2.psm1'
# Invoke-WebRequest -Uri $Uri -OutFile "$hnsDir/hns.psm1"

# # Add the HNS module to the PSModulePath environment variable
# $env:PSModulePath += ";$hnsDir"

# $failed = $false

# # Test the import of the HNS module
# Write-Debug "Testing import of HNS module..."
# if (-not (Get-Module -ListAvailable -Name "HNS")) {
#     Write-Error "HNS module not found. Please ensure the HNS module is installed correctly." -ErrorAction Continue
#     $failed = $true
# }
# Write-Host "HNS module imported successfully." -ForegroundColor Green

# # Import the Contaners Toolkit module
# Write-Debug "Importing the Containers Toolkit module from: $ManifestPath"
# Import-Module -Name "$ManifestPath" -Force -ErrorAction Stop

# # Test the import of the Containers Toolkit module
# Write-Debug "Testing import of Containers Toolkit module..."
# if (-not (Get-Module -Name "Containers-Toolkit")) {
#     Write-Error "Containers Toolkit module not found. Please ensure the module is installed correctly." -ErrorAction Continue
#     $failed = $true
# }
# else {
#     Write-Host "Containers Toolkit module imported successfully." -ForegroundColor Green
# }

# if ($failed) {
#     Write-Error "Module import failed. Please check the output for details." -ErrorAction Continue
#     exit 1
# }

# # Install the container tools
# # - install all the tools
# # - register containerd and buildkitd services
# # - initialize a new NAT network
# Write-Host "Installing the latest version of the container tools..."
# Install-Containerd -Setup -Force -Confirm:$false
# Install-Buildkit -Setup -Force -Confirm:$false
# Install-Nerdctl -Force -Confirm:$false
# Initialize-NatNetwork -Gateway 192.168.0.1 -Force -Confirm:$false

# # Verify the container tools installation
# Write-Host "Verifying container tools installation..."
# $toolInfo = Show-ContainerTools -Latest
# Write-Output $toolInfo
# if ($toolInfo -eq $null) {
#     Write-Error "Container tools installation verification failed." -ErrorAction Continue
#     $failed = $true
# }

# # Test the installation of the container tools
# Write-Host "Test containerd service has been registered..."
# Get-Service -Name containerd -ErrorAction Stop | Format-List -Property *

# # Test the installation of the buildkitd service
# Write-Host "Test buildkitd service has been registered..."
# Get-Service -Name buildkitd -ErrorAction Stop | Format-List -Property *

# # Test the initialization of a NAT network
# Write-Host "Test NAT network has been created..."
# $hnsNetwork = Get-HnsNetwork | Where-Object { $_.Name -eq "Nat" }
# if (-not $hnsNetwork) {
#     Write-Error "No network named 'Nat' found. NAT network initialization failed." -ErrorAction Continue
#     $failed = $true
# }
# Write-Output $hnsNetwork

# if ($failed) {
#     Write-Error "One or more tests failed. Please check the output for details." -ErrorAction Continue
#     exit 1
# }

# # Uninstall the container tools
# Write-Host "Uninstalling the container tools..."
# Uninstall-Containerd -Force -Confirm:$false -ErrorAction Continue
# Uninstall-Buildkit -Force -Confirm:$false -ErrorAction Continue
# Uninstall-Nerdctl -Force -Confirm:$false -ErrorAction Continue


# # Verify the uninstallation of the container tools
# $tools = @(
#     "containerd",
#     "buildkit",
#     "nerdctl"
# )
# foreach ($tool in $tools) {
#     Write-Host "Verifying $tool has been uninstalled..."
#     $retryCount = 3
#     while ($retryCount -gt 0) {
#         Write-Debug "Retrying to verify uninstallation of $tool... ($retryCount retries left)"
#         $command = Get-Command -Name $tool -ErrorAction SilentlyContinue | Where-Object { $_.Source -like "$env:programfiles\*" }
#         if ($command) {
#             Start-Sleep -Seconds 5
#             $retryCount--

#             if ($retryCount -eq 0) {
#                 Write-Error "Failed to uninstall $tool after multiple attempts." -ErrorAction Continue
#                 $failed = $true
#             }
#         }
#         else {
#             break
#         }
#     }
# }

# $services = @(
#     "containerd",
#     "buildkitd"
# )
# foreach ($service in $services) {
#     Write-Host "Verifying $service service has been unregistered..."
#     $retryCount = 3
#     while ($retryCount -gt 0) {
#         Write-Debug "Retrying to verify unregistration of $service service... ($retryCount retries left)"
#         $serviceObj = Get-Service -Name $service -ErrorAction SilentlyContinue
#         if ($serviceObj) {
#             Start-Sleep -Seconds 5
#             $retryCount--

#             if ($retryCount -eq 0) {
#                 Write-Error "Failed to unregister $service service after multiple attempts." -ErrorAction Continue
#                 $failed = $true
#             }
#         }
#         else {
#             break
#         }
#     }
# }

# if ($failed) {
#     Write-Error "Uninstallation of one or more container tools failed. Please check the output for details." -ErrorAction Continue
#     exit 1
# }

# # Summary
# Write-Host "E2E script completed successfully."
