$envPathRegKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

class ContainerTool {
    [ValidateNotNullOrEmpty()][string]$Feature
    [ValidateNotNullOrEmpty()][string]$Version
    [ValidateNotNullOrEmpty()][string]$Uri
    [string]$InstallPath
    [string]$DownloadPath
    [string]$EnvPath
}

enum ActionConsent {
    Yes = 0
    No = 1
}

function Get-LatestToolVersion($repository) {
    try {
        $uri = "https://api.github.com/repos/$repository/releases/latest"
        $response = Invoke-WebRequest -Uri $uri
        $version = ($response.content  | ConvertFrom-Json).tag_name
        return $version.TrimStart("v")
    }
    catch {
        Throw "Could not get $repository version. $_"
    }
}

function Get-InstallationFiles {
    param(
        [PSCustomObject[]]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Files to download")]
        $Files
    )
    
    Write-Information -InformationAction Continue -MessageData "Downloading container tools files"

    if (!(Get-Module -Name ThreadJob)) {
        Install-Module -Name ThreadJob -Scope CurrentUser
    }

    $jobs = @()
    
    # Create multiple thread jobs to download multiple files at the same time.
    foreach ($file in $files) {
        $jobs += Start-ThreadJob -Name $file.DownloadPath `
            -ScriptBlock {
            $feature = $using:file

            Write-Information -InformationAction Continue -MessageData "Downloading $($feature.Feature) version $($feature.Version)"
            try {
                    
                Invoke-WebRequest -Uri $feature.Uri -OutFile $feature.DownloadPath
                
                Write-host $LASTEXITCODE -ForegroundColor Magenta
                Write-host $ERROR[0].Exception.Message-ForegroundColor Magenta

                if ($LASTEXITCODE -gt 0) {
                    Throw $ERROR[0].Exception.Message
                }
            }
            catch {
                Write-Error "Downlooad failed for $($feature.feature): $($feature.uri). $_"
                exit
            }
        }
    }

    Wait-Job -Job $jobs | Out-Null

    foreach ($job in $jobs) {
        Receive-Job -Job $job | Out-Null
    }
}

function Get-DefaultInstallPath($tool) {
    switch ($tool) {
        "buildkit" { 
            $executable = "build*.exe"
        }
        Default {
            $executable = "$tool.exe"
        }
    }

    $sourceCommand = Get-Command -Name $executable  | Where-Object { $_.Source -like "*$tool*" } | Select-Object -Unique 
    $source = $sourceCommand | Select-Object Source
    if ($source) {
        return (Split-Path -Parent $source[0].Source).TrimEnd("\bin")
    }
    return "$Env:ProgramFiles\$tool"  
}

function Install-RequiredFeature {
    param(
        [string] $Feature,
        [string] $InstallPath,
        [string] $DownloadPath,
        [string] $EnvPath,
        [boolean] $cleanup
    )
    
    # Create the directory to untar to
    Write-Information -InformationAction Continue -MessageData "Extracting $Feature to $InstallPath"
    if (!(Test-Path $InstallPath)) { 
        New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null 
    }

    # Untar file
    if ($DownloadPath.EndsWith("tar.gz")) {
        tar.exe -xf $DownloadPath -C $InstallPath
        if ($LASTEXITCODE -gt 0) {
            Throw "Could not untar $DownloadPath. $_"
        }
    }

    # Add to env path
    Add-FeatureToPath -Feature $Feature -Path $EnvPath

    # Clean up
    if ($CleanUp) {
        Write-Output "Cleanup to remove downloaded files"
        Remove-Item $downloadPath -Force -ErrorAction Continue
    }
}

function Uninstall-ContainerTool ($tool, $path) {
    $pathItems = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
    if ($null -eq $pathItems) {
        return
    }

    $title = "$tool already exists at $path."
    $question = "Do you want to uninstall $tool before proceeding?"
    $choices = '&Yes', '&No'
    $consent = $Host.UI.PromptForChoice($title, $question, $choices, 1)

    if ([ActionConsent]$consent -eq [ActionConsent]::No) {
        Throw "$tool installation cancelled. $tool already exists at $path."
    }

    Write-Warning "Uninstalling preinstalled $tool at the path $path"
    try {
        $command = "Uninstall-$tool -Path '$path'"
        Invoke-Expression -Command $command
    }
    catch {
        Throw "Could not uninstall $tool. $_"
    }
}

function Add-FeatureToPath {
    param (
        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Feature to add to env path")]
        $feature,

        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Path where the feature is installed")]
        $path
    )

    $currPath = (Get-ItemProperty -Path $envPathRegKey -Name path).path
    $currPath = ParsePathString -PathString $currPath
    if (!($currPath -like "*$feature*")) {
        Write-Information -InformationAction Continue -MessageData "Adding $feature to Environment Path RegKey"

        # Add to reg key
        Set-ItemProperty -Path $envPathRegKey -Name PATH -Value "$currPath;$path"
    }

    $currPath = ParsePathString -PathString $env:Path
    if (!($currPath -like "*$feature*")) {
        Write-Information -InformationAction Continue -MessageData "Adding $feature to env path"
        # Add to env path
        [Environment]::SetEnvironmentVariable("Path", "$($env:path);$path", [System.EnvironmentVariableTarget]::Machine)
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    }
}

function Remove-FeatureFromPath {
    param (
        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Feature to remove from env path")]
        $feature
    )
    
    # Remove from regkey
    $currPath = (Get-ItemProperty -Path $envPathRegKey -Name path).path
    $currPath = ParsePathString -PathString $currPath
    if ($currPath -like "*$feature*") {
        $NewPath = removeFeatureFromPath -PathString $currPath -Feature $feature
        Set-ItemProperty -Path $envPathRegKey -Name PATH -Value $NewPath
    }
    
    # Remove from env path
    $currPath = ParsePathString -PathString $env:Path
    if ($currPath -like "*$feature*") {
        Write-Information -InformationAction Continue -MessageData "Removing $feature from env path"
        $newPathString = removeFeatureFromPath -PathString $currPath -Feature $feature
        [Environment]::SetEnvironmentVariable("Path", "$newPathString", [System.EnvironmentVariableTarget]::Machine)
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    }
}

function ParsePathString($pathString) {
    $parsedString = $pathString -split ";" | `
        ForEach-Object { $_.TrimEnd("\") } | `
        Select-Object -Unique | `
        Where-Object { ![string]::IsNullOrWhiteSpace($_) }

    if (!$parsedString) {
        $DebugPreference = 'Stop'
        Write-Debug "Env path cannot be null or an empty string"
    }
    return $parsedString -join ";"
}

function RemoveFeatureFromPath ($pathString, $feature) {
    $parsedString = $pathString -split ";" |  Where-Object { !($_ -like "*$feature*") }

    if (!$parsedString) {
        $DebugPreference = 'Stop'
        Write-Debug "Env path cannot be null or an empty string"
    }
    return $parsedString -join ";"
}

Export-ModuleMember -Function Get-LatestToolVersion
Export-ModuleMember -Function Get-DefaultInstallPath
Export-ModuleMember -Function Get-InstallationFiles
Export-ModuleMember -Function Install-RequiredFeature
Export-ModuleMember -Function Uninstall-ContainerTool
Export-ModuleMember -Function Add-FeatureToPath
Export-ModuleMember -Function Remove-FeatureFromPath
