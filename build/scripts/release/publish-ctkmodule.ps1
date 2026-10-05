###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

<#
.SYNOPSIS
Publishes the Containers-Toolkit module to the PowerShell Gallery.

.PARAMETER ModulePath
The path to the directory containing the module to publish. "containers-toolkit/"

.PARAMETER ApiKey
The PSGallery API key to use to publish the module.

.PARAMETER ReleaseNotesPath
Path to the release notes. Defaults to empty string.

.PARAMETER Staging
If specified, the module will be published to the staging repository.

.PARAMETER Credential
The credentials to use to register a repository. This is required if the staging repository does not exist.
To generate credentials, use the following command:
    $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $env:GITHUB_ACTOR, (ConvertTo-SecureString $env:GITHUB_TOKEN -AsPlainText -Force)

Alternatively, you can use a key vault to store the credentials and retrieve them using the following command:
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/register-psresourcerepository?view=powershellget-3.x#example-4
    $akv = Get-AzKeyVaultSecret -VaultName "<VAULT-NAME>" -Name "<SECRET-NAME>"
    $Credential = New-Object System.Management.Automation.PSCredential("<VAULT-NAME", "<SECRET-NAME>")

#>


[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [String]$ModulePath = "./containers-toolkit",

    [Parameter(Mandatory = $true)]
    [String]$ApiKey,

    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String]$ReleaseNotesPath,

    [Parameter(Mandatory = $false)]
    [Switch]$Staging,

    [Parameter(Mandatory = $false)]
    [String]$Credential
)

$ErrorActionPreference = "Stop"

$SCRIPTS_DIR = $PSScriptRoot
$ROOT_DIR = Split-Path -Parent (Split-Path -Parent $SCRIPTS_DIR)
Write-Debug "Root directory: $ROOT_DIR"

# Get module absolute path
$ModulePath = Resolve-Path $ModulePath
$ModuleManifestPath = Join-Path -Path $ModulePath -ChildPath "containers-toolkit.psd1"

# Read the module manifest
Write-Debug "Reading module manifest file: $ModuleManifestPath"
$ModuleManifest = Invoke-Expression -Command (Get-Content -Path $ModuleManifestPath -Raw)
$manifestPsData = $ModuleManifest.PrivateData.PSData

# Get module info
Write-Debug "Getting module info..."
$ModuleInfo = Get-Module -ListAvailable "$ModuleManifestPath"

# Get the module name in Camel Case
Write-Debug "Extracting module name..."
$ModuleName = $ModuleInfo.Name.ToLower()
$separator = '-'
$ModuleName = ($ModuleName -split "$separator" | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1) }) -join "$separator"

# Get the module version
Write-Debug "Extracting module version..."
$ReleaseVersion = $ModuleInfo.Version.ToString()
if ($manifestPsData.Prerelease) {
    $ReleaseVersion = "$ReleaseVersion-$($manifestPsData.Prerelease)"
}

# Get the release notes
Write-Debug "Getting release notes..."
$ReleaseNotes = if ($ReleaseNotesPath) { Get-Content -Path $ReleaseNotesPath -Raw } else { '' }

# Set variables for the script
Set-Variable -Name ModuleVersion -Value $ReleaseVersion -Scope Script -Force
Set-Variable -Name ModuleName -Value $ModuleName -Scope Script -Force
Set-Variable -Name ModuleManifestPath -Value $ModuleManifestPath -Scope Script -Force
Set-Variable -Name ReleaseNotes -Value $ReleaseNotes -Scope Script -Force
Set-Variable -Name ApiKey -Value $ApiKey -Scope Script -Force
Set-Variable -Name Staging -Value $Staging -Scope Script -Force

function Register-CossRepository {
    param (
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName
    )

    $repository = Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue
    if ($repository) {
        return
    }

    if (-not $Credential) {
        Write-Error ([System.ArgumentNullException]::new("Credential is required to register a repository. Please provide a valid credential using the '-Credential' parameter.")) -ErrorAction Stop
    }

    $Uri = "https://nuget.pkg.github.com/microsoft/index.json"
    Write-Host "Registering repository...`n`t{ Name: '$RepositoryName', Uri: '$Uri' }"
    Register-PSResourceRepository -Name $RepositoryName -Trusted -Uri "$Uri" -Credential $Credential
}

function New-NugetSpec {
    # Update the nuget spec
    $NugetSpecPath = Join-Path -Path (Split-Path -Parent $ModulePath) -ChildPath "containers-toolkit.nuspec"
    if (-not (Test-Path -Path $NugetSpecPath)) {
        Write-Host "Creating nuspec file: '$NugetSpecPath'"
        nuget.exe spec "$ModuleName"
    }

    # Read the nuspec file
    [xml]$NugetSpec = Get-Content $NugetSpecPath
    $metadata = $NugetSpec.package.metadata
    $files = $NugetSpec.package.files

    # Update nuspec file metadata
    $metadata.version = $ReleaseVersion
    $metadata.authors = $ModuleManifest.Author
    $metadata.description = $ModuleManifest.Description
    $metadata.copyright = $ModuleManifest.Copyright
    $metadata.requireLicenseAcceptance = $manifestPsData.RequireLicenseAcceptance.ToString().ToLower()
    $metadata.projectUrl = $manifestPsData.ProjectUri
    $metadata.releaseNotes = $manifestPsData.releaseNotes
    $metadata.tags = ($manifestPsData.Tags -join ' ')

    # Update release branch
    $branchName = "release/v$ReleaseVersion"
    $repoNode = $metadata.SelectSingleNode("repository")
    if (!$repoNode) {
        Write-Debug "Creating <repository> node in the nuspec file"
        $repoNode = $NugetSpec.CreateElement("repository")
        $repoNode.SetAttribute("type", "git")
        $repoNode.SetAttribute("url", "$($manifestPsData.ProjectUri)")
        $metadata.AppendChild($repoNode) | Out-Null
    }
    $repoNode.SetAttribute("branch", "$branchName") | Out-Null

    # Create the <files> node if it doesn't exist
    if (!$files) {
        Write-Debug "Creating <files> node in the nuspec file"
        $files = $NugetSpec.CreateElement("files")
        $NugetSpec.package.AppendChild($files) | Out-Null
    }
    $filesNode = $NugetSpec.package.SelectSingleNode("files")

    # Add files to the nuspec file
    @( "LICENSE", "README.md") | ForEach-Object {
        $fileInfo = Get-ChildItem -Path $ROOT_DIR -File -Filter "$_" -ErrorAction SilentlyContinue | Select-Object -First 1
        $fileName = $fileInfo.Name
        if ($fileName) {
            $f = [System.IO.Path]::GetFileNameWithoutExtension($fileName).ToLower() # File name without extension
            if ($f -eq "LICENSE") {
                $fileName = "LICENSE.txt"
                Copy-Item -Path $fileInfo.FullName -Destination "$ROOT_DIR/$fileName" -Force | Out-Null
            }

            # Update the <readme> node and <license> node
            $elementNode = $metadata.SelectSingleNode($f)
            if ($elementNode) {
                $metadata.RemoveChild($elementNode) | Out-Null
            }
            Write-Debug "Adding '$fileName' element to nuspec file"
            $elementNode = $NugetSpec.CreateElement($f)
            if ($f -eq "LICENSE") { $elementNode.SetAttribute("type", "file") }
            $elementNode.InnerText = $([System.IO.Path]::GetFileName($fileName))
            $metadata.AppendChild($elementNode) | Out-Null

            # Update the <files> node
            $fileNode = $filesNode.SelectSingleNode("file[@src='$fileName']")
            if (!$fileNode) {
                Write-Debug "Adding '$fileName' file to nuspec file"
                $fileNode = $NugetSpec.CreateElement("file")
                $fileNode.SetAttribute("src", $([System.IO.Path]::GetFileName($fileName)))
                $fileNode.SetAttribute("target", "")
                $filesNode.AppendChild($fileNode) | Out-Null
            }
        }
    }

    # Create the <dependencies> node if it doesn't exist
    $dependenciesNode = $metadata.SelectSingleNode("dependencies")
    if (!$dependenciesNode) {
        Write-Debug "Creating <dependencies> node in the nuspec file"
        $dependenciesNode = $NugetSpec.CreateElement("dependencies")
        $metadata.AppendChild($dependenciesNode) | Out-Null
    }

    # Remove default grouped dependencies
    if ($metadata.dependencies.group) {
        Write-Debug "Removing default grouped dependencies from the nuspec file"
        $groupNode = $metadata.SelectSingleNode("dependencies").SelectSingleNode("group")
        $metadata.dependencies.RemoveChild($groupNode) | Out-Null
    }

    # Update the dependencies
    $dependencies = $manifestPsData.ExternalModuleDependencies
    if ($dependencies) {
        # Add dependencies
        Write-Debug "Adding dependencies to the nuspec file"
        foreach ($dependency in $dependencies ) {
            # Check if the dependency already exists
            $existingDependency = $metadata.SelectSingleNode("dependencies/dependency[@id='$dependency']")
            if ($existingDependency) {
                Write-Debug "Dependency '$dependency' already exists in the nuspec file"
                continue
            }
            $dependencyElement = $NugetSpec.CreateElement("dependency")
            $dependencyElement.SetAttribute("id", $dependency)
            $dependencyElement.SetAttribute("version", "0.0.0")
            $metadata.SelectSingleNode("dependencies").AppendChild($dependencyElement) | Out-Null
        }
    }

    # Update the nuget spec file
    $NugetSpec.Save($NugetSpecPath)

    return $NugetSpecPath
}

function Publish-CTKModule {
    param (
        [Parameter(Mandatory = $false)]
        [String]$RepositoryName = "PsGallery",

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [String]$Path
    )

    Write-Host "Publishing module...`n`t{ Repository: '$RepositoryName',  Source: '$Path' }"

    # Set parameters for Publish-PSResource
    $params = @{
        Repository = "$RepositoryName"
    }
    switch ($RepositoryName) {
        "PsGallery" {
            $params.Path = $Path
        }
        Default {
            $params.NupkgPath = $Path
        }
    }
    Write-Debug "Publish-PSResource parameters: $([pscustomobject]$params)"

    # Set the API key
    $params.ApiKey = $ApiKey

    # Publish the module
    Publish-PSResource @params
}


################################################################
################################################################
######################## PUBLISH MODULE ########################
################################################################
################################################################

# Parameters: PSGallery
$ReleasePath = $ModulePath
$RepositoryName = "PSGallery"

# Parameters: staging repository
if ($Staging) {
    # Register the staging repository
    $RepositoryName = "COSS.CTK.Staging"
    Register-CossRepository -RepositoryName $RepositoryName

    # Generate nuget spec
    $NugetSpecPath = New-NugetSpec

    # Pack the module
    Write-Host "Packing module to nuget package...`n`t{ Source: '$NugetSpecPath' }"
    nuget pack "$NugetSpecPath" -BasePath "$ROOT_DIR" -OutputDirectory "$ROOT_DIR"

    # Get the nuget package
    $nugetPackages = Get-ChildItem -Path "$OutputDirectory" -Filter "$ModuleName*.nupkg"
    if ($nugetPackages.Count -eq 0) {
        Write-Error "No nuget packages found in '$ModulePath'"
        return
    }

    if ($nugetPackages.Count -gt 1) {
        $packagePaths = $nugetPackages.FullName -join ", "
        Write-Error "Multiple nuget packages found in '$ModulePath': $packagePaths"
    }

    # Parameters for Publish-Module
    $ReleasePath = $nugetPackages[0].FullName
}

# Publish the module
$params = @{
    RepositoryName = $RepositoryName
    Path           = $ReleasePath
}
Publish-CTKModule @params

# Clean up
Write-Debug "Cleaning up files..."
@("LICENSE.txt", "*.nupkg") | ForEach-Object {
    Write-Debug "Removing files: $_"
    Get-ChildItem -Path "$ROOT_DIR" -Filter "$_" | Remove-Item -Force -ErrorAction SilentlyContinue
}
