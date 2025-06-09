<#
.SYNOPSIS
Loads Newtonsoft.Json and Newtonsoft.Json.Schema assemblies from NuGet.

.DESCRIPTION
This script loads the Newtonsoft.Json and Newtonsoft.Json.Schema assemblies from NuGet.
It checks if the assemblies are already loaded, installs them if not, and then loads them.

.PARAMETER Path
The path where the assemblies will be installed or loaded from. If not specified, it defaults to the user's profile directory.

.EXAMPLE
.\Load-NewtonsoftDlls.ps1 -Path "C:\Path\To\Your\Modules"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the assemblies will be installed or loaded from.")]
    [string]$Path
)

function Get-DllFile {
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    $dllPath = Get-ChildItem -Path "$Path" -Filter "$PackageName.dll" -File -Recurse -ErrorAction SilentlyContinue | `
        Select-Object -First 1 -ExpandProperty FullName

    return $dllPath
}

function Import-NewtonsoftDll {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Newtonsoft.Json", "Newtonsoft.Json.Schema")]
        [string]$PackageName,

        [Parameter(Mandatory = $false)]
        [string]$Path
    )

    Write-Host "Loading $PackageName assembly..." -ForegroundColor Cyan

    # Check if the assembly is already loaded
    $loadedAssemblies = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
        $_.GetName().Name -eq "$PackageName"
    }
    if ($loadedAssemblies) {
        Write-Warning "$PackageName already loaded.`n`tLocation: '$($loadedAssemblies.Location)'"
        return
    }

    # Set the default path if not provided
    if (-not $Path) {
        $profileDir = Split-Path -Parent "$($PROFILE.CurrentUserCurrentHost)"
        $Path = Join-Path -Path "$profileDir" -ChildPath "Modules\newtonsoft.json"
    }
    Write-Debug "Path: $Path"
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }

    $framework = if ($PSVersionTable.PSEdition -eq "Core") { "netstandard2.0" } else { "net45" }
    $assembliesDir = Join-Path -Path $Path -ChildPath "$PackageName\lib\$framework"
    Write-Debug "Package directory: $assembliesDir"

    # Install the package if it doesn't exist from nuget
    $dllPath = Get-DllFile -Path $assembliesDir -PackageName $PackageName

    if (-not $dllPath) {
        # Check if nuget.exe is available
        if (-not (Get-Command nuget.exe -ErrorAction SilentlyContinue)) {
            Write-Error "'nuget.exe' not found in PATH. Please install or add it to PATH."
            return
        }

        Write-Host "Installing $PackageName from NuGet." -ForegroundColor Cyan
        nuget.exe install $PackageName -NoHttpCache -ExcludeVersion -NonInteractive -Force `
            -OutputDirectory $Path `
            -Framework $framework

        $dllPath = Get-DllFile -Path $assembliesDir -PackageName $PackageName
        if (-not $dllPath) {
            Write-Error "The $PackageName.dll file could not be found in the provided directory after install."
            return
        }
    }

    # Load the assembly from the path
    try {
        Write-Host "Loading assembly from '$dllPath'." -ForegroundColor Magenta
        $asm = [Reflection.Assembly]::LoadFile($dllPath)
        Write-Debug $asm
    }
    catch {
        Write-Error "Failed to load assembly from '$dllPath'. $_"
        return
    }
}

Import-NewtonsoftDll -Path $Path -PackageName "Newtonsoft.Json.Schema"
Import-NewtonsoftDll -Path $Path -PackageName "Newtonsoft.Json"
