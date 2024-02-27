﻿###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


$ModuleParentPath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ModuleParentPath\Private\UpdateEnvironmentPath.psm1" -Force

class ContainerTool {
    [ValidateNotNullOrEmpty()][string]$Feature
    [ValidateNotNullOrEmpty()][string]$Version
    [ValidateNotNullOrEmpty()][string]$Uri
    [string]$InstallPath
    [string]$DownloadPath
    [string]$EnvPath
}

Add-Type @'
public enum ActionConsent {
    Yes = 0,
    No = 1
}
'@


function Get-LatestToolVersion($repository) {
    try {
        $uri = "https://api.github.com/repos/$repository/releases/latest"
        $response = Invoke-WebRequest -Uri $uri -UseBasicParsing
        $version = ($response.content | ConvertFrom-Json).tag_name
        return $version.TrimStart("v")
    }
    catch {
        $tool = ($repository -split "/")[1]
        Throw "Could not get $tool latest version. $($_.Exception.Message)"
    }
}

function Test-EmptyDirectory($path) {
    if (-not (Test-Path -Path $path)) {
        return $true
    }

    $pathItems = Get-ChildItem -Path $path -Recurse -ErrorAction Ignore | Where-Object {
        !$_.PSIsContainer -or ($_.PSIsContainer -and $_.GetFileSystemInfos().Count -ne 0) }
    if (!$pathItems) {
        return $true
    }

    $itemCount = $pathItems | Measure-Object
    return ($itemCount.Count -eq 0)
}

function Get-InstallationFiles {
    param(
        [parameter(Mandatory, HelpMessage = "Files to download")]
        [PSCustomObject[]] $Files
    )

    begin {
        function downloadfile ($feature) {
            Write-Information -InformationAction Continue -MessageData "Downloading $($feature.Feature) version $($feature.Version)"
            try {
                Invoke-WebRequest -Uri $feature.Uri -OutFile $feature.DownloadPath -UseBasicParsing
            }
            catch {
                Throw "$($feature.feature) downlooad failed: $($feature.uri).`n$($_.Exception.Message)"
            }
        }

        $jobs = @()
    }

    process {
        # Download file from repo
        if ($Files.Length -eq 1) {
            downloadfile -feature $Files[0]
        }
        else {
            # Download files asynchronously
            Write-Information -InformationAction Continue -MessageData "Downloading container tools files"

            if (!(Get-Module -ListAvailable -Name ThreadJob)) {
                Install-Module -Name ThreadJob -Scope CurrentUser -Force
            }
            Import-Module -Name ThreadJob -Force

            # Create multiple thread jobs to download multiple files at the same time.

            foreach ($file in $files) {
                # TODO: Test what happens if one call fails
                $jobs += Start-ThreadJob -Name $file.DownloadPath -ScriptBlock { downloadfile -Feature $using:file }
            }

            Wait-Job -Job $jobs | Out-Null

            foreach ($job in $jobs) {
                Receive-Job -Job $job | Out-Null
            }
        }
    }

    end {
        $jobs | Remove-Job -Force
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

    $source = Get-Command -Name $executable -ErrorAction Ignore | `
        Where-Object { $_.Source -like "*$tool*" } | `
        Select-Object Source -Unique
    if ($source) {
        return (Split-Path -Parent $source[0].Source) -replace '(\\bin)$', ''
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
    $output = Invoke-ExecutableCommand -Executable 'tar.exe' -Arguments "-xf `"$DownloadPath`" -C `"$InstallPath`""
    if ($output.ExitCode -ne 0) {
        Throw "Could not untar file $DownloadPath at $InstallPath. $($output.StandardError.ReadToEnd())"
    }

    # Add to env path
    Add-FeatureToPath -Feature $Feature -Path $EnvPath

    # Clean up
    if ($CleanUp) {
        Write-Output "Cleanup to remove downloaded files"
        Remove-Item $downloadPath -Force -ErrorAction Ignore
    }
}

function Uninstall-ContainerToolConsent ($tool, $path) {
    $question = "Do you want to uninstall $tool from $($path)?"
    $choices = '&Yes', '&No'

    $defaultChoice = [ActionConsent]::No.value__
    $consent = (Get-Host).UI.PromptForChoice($warning, $question, $choices, $defaultChoice)

    return [ActionConsent]$consent -eq [ActionConsent]::Yes
}

function Add-FeatureToPath ($Path, $Feature) {
    @("User", "System") | ForEach-Object { Update-EnvironmentPath -Tool $Feature -Path $Path -Action 'Add' -PathType $_ }
}

function Remove-FeatureFromPath ($Feature) {
    @("User", "System") | ForEach-Object { Update-EnvironmentPath -Tool $Feature -Action 'Remove' -PathType $_ }
}

function Test-ServiceRegistered ($service) {
    $scQueryResult = (sc.exe query $service) | Select-String -Pattern "SERVICE_NAME: $service"
    return ($null -ne $scQueryResult)
}

function Invoke-ServiceAction ($Action, $service) {
    if (!(Test-ServiceRegistered -Service $service)) {
        throw "$service service does not exist as an installed service."
    }

    switch ($Action) {
        'Start' {
            $status = 'Running'
            $command = 'Start-Service'
        }
        'Stop' {
            $status = 'Stopped'
            $command = 'Stop-Service -NoWait -Force'
        }
        Default {
            Throw 'Not implemented'
        }
    }

    $serviceInfo = Get-Service $service -ErrorAction Ignore
    if (!$serviceInfo) {
        Throw "$service service does not exist as an installed service."
    }

    try {
        Invoke-Expression "$command -Name $service"

        # Waiting for buildkit to come to steady state
        (Get-Service -Name $service -ErrorAction Ignore).WaitForStatus($status, '00:00:30')

        Write-Output "Success: { Service: $service, Action: $Action }"
    }
    catch {
        Throw "Couldn't $action $service service. $_"
    }
}

function Invoke-ExecutableCommand {
    param (
        [parameter(Mandatory)]
        [String] $executable,
        [parameter(Mandatory)]
        [String] $arguments
    )

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $executable
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()

    return $p
}


Export-ModuleMember -Function Get-LatestToolVersion
Export-ModuleMember -Function Get-DefaultInstallPath
Export-ModuleMember -Function Test-EmptyDirectory
Export-ModuleMember -Function Get-InstallationFiles
Export-ModuleMember -Function Install-RequiredFeature
Export-ModuleMember -Function Uninstall-ContainerToolConsent
Export-ModuleMember -Function Invoke-ExecutableCommand
Export-ModuleMember -Function Test-ServiceRegistered
Export-ModuleMember -Function Add-FeatureToPath
Export-ModuleMember -Function Remove-FeatureFromPath
Export-ModuleMember -Function Invoke-ServiceAction
