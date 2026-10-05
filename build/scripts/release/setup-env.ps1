<#
    This script sets up the environment for releasing the Containers-Toolkit modules.
    It installs the required modules and sets up the PSGallery repository.
#>

Write-Host "Installing Nuget provider..."
Install-PackageProvider -Name NuGet -Force -ErrorAction Continue | Out-Null

# Install the latest version of PowerShellGet and PackageManagement
@("PowerShellGet", "PackageManagement") | ForEach-Object {
    $ModuleName = $_

    if (Get-Module -ListAvailable -Name $ModuleName) {
        Write-Host "Updating $ModuleName..."
        Update-Module $ModuleName -AcceptLicense -Confirm:$false -Force -ErrorAction Continue
    }
    else {
        Write-Host "Installing $ModuleName..."
        Install-Module $ModuleName -AllowClobber -Force -ErrorAction Continue
    }
}

# Install the latest version of Microsoft.PowerShell.PSResourceGet
if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet)) {
    Write-Host "Installing Microsoft.PowerShell.PSResourceGet..."
    Install-Module Microsoft.PowerShell.PSResourceGet -AllowClobber -Force -ErrorAction Continue
}

# Validate the installation
Get-Module Microsoft.PowerShell.PSResourceGet -ListAvailable | Format-List

# Set PSGallery as trusted repository
Write-Host "Setting PSGallery as trusted repository..."
try {
    $PSGallery = Get-PSResourceRepository -Name "PSGallery" -ErrorAction Stop
    if (-not $PSGallery.Trusted) {
        Write-Host "Setting PSGallery as trusted repository..."
        Set-PSResourceRepository -Name "PSGallery" -Trusted -ErrorAction Stop
    }
}
catch {
    Write-Host "Initializing PSResourceRepository store..."
    Register-PSResourceRepository -PSGallery -Trusted -ErrorAction Stop
}
