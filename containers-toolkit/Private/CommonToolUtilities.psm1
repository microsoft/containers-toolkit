###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

using module "..\Private\logger.psm1"

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

class FileDigest {
    [string]$HashFunction
    [string]$Digest

    FileDigest([string]$hashFunction, [string]$digest) {
        $this.HashFunction = $hashFunction
        $this.Digest = $digest
    }
}

class FileDownloadParameters {
    [ValidateSet("Containerd", "Buildkit", "nerdctl", "WinCNIPlugin")]
    [string]$Feature
    [string]$Repo
    [string]$Version = "latest"
    [ValidateSet("386", "amd64", "arm64", "arm")]
    [string]$OSArchitecture = "$env:PROCESSOR_ARCHITECTURE"
    [string]$DownloadPath = "$HOME\Downloads"
    [string]$ChecksumSchemaFile
    [string]$FileFilterRegEx

    FileDownloadParameters(
        [string]$feature,
        [string]$repo,
        [string]$version = "latest",
        [string]$arch = "$env:PROCESSOR_ARCHITECTURE",
        [string]$downloadPath = "$HOME\Downloads",
        [string]$checksumSchemaFile = $null,
        [string]$fileFilterRegEx = $null
    ) {
        $this.Feature = $feature
        $this.Repo = $repo
        $this.Version = $version
        $this.OSArchitecture = $arch
        $this.DownloadPath = $downloadPath
        $this.ChecksumSchemaFile = $checksumSchemaFile
        $this.FileFilterRegEx = $fileFilterRegEx
    }
}


Add-Type @'
public enum ActionConsent {
    Yes = 0,
    No = 1
}
'@

$HASH_FUNCTIONS = @("SHA1", "SHA256", "SHA384", "SHA512", "MD5")
$HASH_FUNCTIONS_STR = $HASH_FUNCTIONS -join '|' # SHA1|SHA256|SHA384|SHA512|MD5
$NERDCTL_CHECKSUM_FILE_PATTERN = "(?<hashfunction>(?:^({0})))" -f ($HASH_FUNCTIONS -join '|')
$NERDCTL_FILTER_SCRIPTBLOCK_STR = { (("{0}" -match "$NERDCTL_CHECKSUM_FILE_PATTERN") -and "{0}" -notmatch ".*.asc$") }.ToString()


Set-Variable -Option AllScope -scope Global -Visibility Public -Name "CONTAINERD_REPO" -Value "containerd/containerd" -Force
Set-Variable -Option AllScope -scope Global -Visibility Public -Name "BUILDKIT_REPO" -Value "moby/buildkit" -Force
Set-Variable -Option AllScope -scope Global -Visibility Public -Name "NERDCTL_REPO" -Value "containerd/nerdctl" -Force
Set-Variable -Option AllScope -scope Global -Visibility Public -Name "WINCNI_PLUGIN_REPO" -Value "microsoft/windows-container-networking" -Force
Set-Variable -Option AllScope -scope Global -Visibility Public -Name "CLOUDNATIVE_CNI_REPO" -Value "containernetworking/plugins" -Force


function Get-LatestToolVersion($tool) {
    # Get the repository based on the tool
    $repository = switch ($tool.ToLower()) {
        "containerd" { $CONTAINERD_REPO }
        "buildkit" { $BUILDKIT_REPO }
        "nerdctl" { $NERDCTL_REPO }
        "wincniplugin" { $WINCNI_PLUGIN_REPO }
        "cloudnativecni" { $CLOUDNATIVE_CNI_REPO }
        Default { Throw "Couldn't get latest $tool version. Invalid tool name: '$tool'." }
    }

    # Get the latest release version URL string
    $uri = "https://api.github.com/repos/$repository/releases/latest"

    [Logger]::Debug("Getting the latest $tool version from $uri")

    # Get the latest release version
    try {
        $response = Invoke-WebRequest -Uri $uri -UseBasicParsing
        $version = ($response.content | ConvertFrom-Json).tag_name
        return $version.TrimStart("v")
    }
    catch {
        Throw "Couldn't get $tool latest version from $uri. $($_.Exception.Message)"
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

function Get-ReleaseAssets {
    [OutputType([PSCustomObject])]
    param (
        [string]$repo, # containers repo-owner/$repo-name
        [string]$version,
        [string]$OSArch
    )

    function Invoke-GitHubApi {
        param($uri)
        try {
            [Logger]::Debug("Invoking GitHub API. URI: $uri")
            $response = Invoke-RestMethod -Uri "$uri" -Headers @{ "User-Agent" = "PowerShell" }
            return $response
        }
        catch {
            Throw "GitHub API error. URL: `"$uri`". Error: $($_.Exception.Message)"
        }
    }

    [Logger]::Debug("Getting release assets:`n`trepo: $repo`n`trelease version: $version`n`trelease architecture: $OSArch ")
    $baseApiUrl = "https://api.github.com/repos/$repo"
    if ($version -eq "latest") {
        $apiUrl = "$baseApiUrl/releases/latest"
    }
    else {
        # We use this method to get the release assets for a specific version
        # because creating a string for the version tag is not always consistent
        # e.g. "v1.0.0" vs "1.0.0"
        # The q parameter used for searching is not available in the GitHub API's /tags endpoint.
        # GitHub's API for listing tags (/repos/{owner}/{repo}/tags) does not support querying or filtering
        # directly through a q parameter like some other endpoints might (e.g., the search API).

        # Get all releases tags
        $response = Invoke-GitHubApi -Uri "$baseApiUrl/tags"
        $releaseTag = $response | Where-Object { ($_.name.TrimStart("v")) -eq ($version.TrimStart("v")) }

        if (-not $releaseTag) {
            Throw "Couldn't find release tags for the provided version: '$version'"
        }

        if ($releaseTag.Count -gt 1) {
            [Logger]::Warning("Found multiple release tags for the provided version: '$version'. Using the first tag.")
        }

        $releaseTagName = $releaseTag | Select-Object -First 1 -ExpandProperty name

        # Get the release with the specified tag
        [Logger]::Debug("Release tag: $releaseTagName")
        $apiUrl = "$baseApiUrl/releases/tags/$releaseTagName"
    }
    $response = Invoke-GitHubApi -Uri "$apiUrl"

    # Filter list of assets by architecture and file name
    $releaseAssets = $response | Select-Object -Property name, url, created_at, published_at, `
    @{ l = "version"; e = { $_.tag_name } }, `
    @{ l = "assets_url"; e = { $_.assets[0].url } }, `
    @{ l = "release_assets"; e = {
            $_.assets |
            Where-Object {
                (
                    # Filter assets by OS (windows) and architecture
                    # In the "zip|tar.gz" regex, we do not add the "$" at the end to allow for checksum files to be included
                    # The checksum files end with eg: ".tar.gz.sha256sum"
                    ($_.name -match "(windows(.+)$OSArch)") -or

                    # nerdctl checksum files are named "SHA256SUMS".
                    (& ([ScriptBlock]::Create($NERDCTL_FILTER_SCRIPTBLOCK_STR -f $_.name)))
                )
            } |
            ForEach-Object {
                [Logger]::Debug(("Asset name: {0}" -f $_.Name))
                [PSCustomObject]@{
                    "asset_name"         = $_.name
                    "asset_download_url" = $_.browser_download_url
                    "asset_size"         = $_.size
                }
            }
        }
    }

    # Check if any release assets were found for the specified architecture
    $archReleaseAssets = $releaseAssets.release_assets | Where-Object { ($_.asset_name -match "windows(.+)$OSArch") }
    if ($archReleaseAssets.Count -eq 0) {
        Throw "Couldn't find release assets for the provided architecture: '$OSArch'"
    }

    if ($archReleaseAssets.Count -lt 2) {
        [Logger]::Warning("Some assets may be missing for the release. Expected at least 2 assets, found $($archReleaseAssets.Count).")
    }

    # Return the assets for the release. Includes the archive file for the binaries and the checksum files.
    return $releaseAssets
}

function Get-InstallationFile {
    [OutputType([string[]])]
    param(
        [parameter(Mandatory, HelpMessage = "Information (parameters) of the file to download")]
        [PSCustomObject] $fileParameters
    )

    begin {
        function Receive-File {
            param($params)

            $MaximumRetryCount = 3
            $RetryIntervalSec = 60
            $lastError = $null  # Store the last exception

            do {
                try {
                    Invoke-WebRequest -Uri $params.Uri -OutFile $params.DownloadPath -UseBasicParsing
                    return
                }
                catch {
                    $lastError = $_  # Store the last error for proper exception handling
                    [Logger]::Warning("Failed to download `"$($params.Feature)`" release assets. Retrying... ($MaximumRetryCount retries left)")
                    Start-Sleep -Seconds $RetryIntervalSec
                    $MaximumRetryCount -= 1
                }
            } until ($MaximumRetryCount -eq 0)

            # Throw the last encountered error after all retries fail
            Throw "Couldn't download `"$($params.Feature)`" release assets from `"$($params.Uri)`".`n$($lastError.Exception.Message)"
        }

        function DownloadAssets {
            param(
                [string]$featureName,
                [string]$version,
                [string]$downloadPath = "$HOME\Downloads",
                [PSCustomObject]$releaseAssets,
                [PSCustomObject]$file
            )

            $archiveFile = $checksumFile = $null
            foreach ($asset in $releaseAssets.PSObject.Properties) {
                $key = $asset.Name
                $asset_params = $asset.Value

                $destPath = Join-Path -Path $downloadPath -ChildPath $asset_params.asset_name
                switch ($key) {
                    "ArchiveFileAsset" { $archiveFile = $destPath }
                    "ChecksumFileAsset" { $checksumFile = $destPath }
                    default { Throw "Invalid input: $key" }
                }

                $downloadParams = [PSCustomObject]@{
                    Feature      = $featureName
                    Version      = $version
                    Uri          = $asset_params.asset_download_url
                    DownloadPath = $destPath
                }

                [Logger]::Debug("Downloading asset $($asset_params.asset_name)...`n`tVersion: $version`n`tURI: $($downloadParams.Uri)`n`tDestination path: $($downloadParams.DownloadPath)")
                try {
                    Receive-File -Params $downloadParams
                }
                catch {
                    [Logger]::Fatal($_.Exception.Message)
                }
            }

            # Verify that both the archive and checksum files were downloaded
            if (-not (Test-Path $archiveFile)) {
                Throw "Archive file not found in the release assets: `'$archiveFile`""
            }
            if (-not (Test-Path $checksumFile)) {
                Throw "Checksum file not found in the release assets: `'$checksumFile`""
            }

            # Verify checksum
            try {
                $isValidChecksum = if ([System.IO.Path]::GetExtension($checksumFile) -eq ".json") {
                    Test-Checksum -JSON -DownloadedFile $archiveFile -ChecksumFile $checksumFile -SchemaFile $file.ChecksumSchemaFile
                }
                else {
                    Test-Checksum -DownloadedFile $archiveFile -ChecksumFile $checksumFile
                }
            }
            catch {
                [Logger]::Fatal("Checksum verification process failed: $($_.Exception.Message)")
            }

            # Remove the checksum file after verification
            if (Test-Path -Path $checksumFile) {
                Remove-Item -Path $checksumFile -Force -ErrorAction SilentlyContinue
            }

            if (-not $isValidChecksum) {
                [Logger]::Error("Checksum verification failed for $archiveFile. The file will be deleted.")

                # Remove the checksum file after verification
                if (Test-Path -Path $archiveFile) {
                    Remove-Item -Path $archiveFile -Force -ErrorAction SilentlyContinue
                }
                Throw "Checksum verification failed. One or more files are corrupted."
            }

            return $archiveFile
        }
    }

    process {
        # Fetch the release assets based on the provided parameters
        $releaseAssets = Get-ReleaseAssets -repo $fileParameters.Repo -version $fileParameters.Version -OSArch $fileParameters.OSArchitecture

        # Filter file names based on the provided regex or default logic
        if ([string]::IsNullOrWhiteSpace($fileParameters.FileFilterRegEx)) {
            # Default logic to filter the archive and checksum files
            $filteredAssets = $releaseAssets.release_assets | Where-Object {
                # In the "zip|tar.gz" regex, we do not add the "$" at the end to allow for checksum files to be included
                # The checksum files end with eg: ".sha256sum"
                ($_.asset_name -match ".*(.zip|.tar.gz)") -or

                # Buildkit checksum files are named ending with ".provenance.json" or ".sbom.json"
                # We only need the ".sbom.json" file
                ($_.asset_name -match ".sbom.json$") -or

                # nerdctl checksum files are named "SHA256SUMS". Check file names that have such a format.
                (& ([ScriptBlock]::Create($NERDCTL_FILTER_SCRIPTBLOCK_STR -f $_.asset_name)))
            }
        }
        else {
            # Use the provided regex to filter the archive and checksum files
            $fileFilterRegEx = $fileParameters.FileFilterRegEx -replace "<__VERSION__>", "v?$($releaseAssets.version.TrimStart('v'))"
            [Logger]::Debug("File filter: `"$fileFilterRegEx`"")
            $filteredAssets = $releaseAssets.release_assets | Where-Object { $_.asset_name -match $fileFilterRegEx }
        }

        # Pair archive and checksum files
        $assetsToDownload = @()
        $archiveExtensionStr = @(".zip", ".tar.gz", ".tgz") -join "|"
        $failedDownloads = @()
        foreach ($asset in $filteredAssets) {
            if ($asset.asset_name -notmatch "(?<extension>$archiveExtensionStr)$") {
                continue
            }

            $fileExtension = $matches.extension

            # Remove the trailing archive file extension to get the checksum file name
            $assetFileName = $asset.asset_name -replace "$fileExtension", ""

            # Find the checksum file that matches the archive
            $checksumAsset = $filteredAssets | Where-Object {
                ($_.asset_name -match "(?:(^$assetFileName).*($HASH_FUNCTIONS_STR))") -or

                # Buildkit checksum is in .sbom.json
                ($_.asset_name -match ".sbom.json$") -or

                (& ([ScriptBlock]::Create($NERDCTL_FILTER_SCRIPTBLOCK_STR -f $_.asset_name)))
            }

            if (-not $checksumAsset) {
                [Logger]::Error("Checksum file for $assetFileName not found. Skipping download.")
                $failedDownloads += $asset.asset_name
                continue
            }

            $assetsToDownload += @{
                FeatureName   = $releaseAssets.name
                Version       = $releaseAssets.version
                DownloadPath  = $fileParameters.DownloadPath
                File          = $fileParameters
                ReleaseAssets = [PSCustomObject]@{
                    ArchiveFileAsset  = $asset
                    ChecksumFileAsset = $checksumAsset
                }
            }
        }

        if ($failedDownloads) {
            $errorMsg = "Failed to find checksum files for $($failedDownloads -join ', ')."
        }

        # Download the archive and verify checksum
        $archiveFiles = $failedDownloads = @()
        [Logger]::Debug("Assets to download count: $($assetsToDownload.ReleaseAssets.Count)")
        foreach ($asset in $assetsToDownload) {
            try {
                [Logger]::Debug("Downloading $($asset.FeatureName) assets...")
                $archiveFile = DownloadAssets @asset

                [Logger]::Debug("Downloaded archive file: `"$archiveFile`"")
                $archiveFiles += $archiveFile
            }
            catch {
                [Logger]::Error("Failed to download assets for `"$($asset.FeatureName)`". $_")
                $failedDownloads += $asset.FeatureName
            }
        }

        if ($errorMsg) {
            Throw "Some files were not downloaded. $errorMsg"
        }

        if ($failedDownloads) {
            Throw "Failed to download assets for $($failedDownloads -join ', '). See logs for detailed error information."
        }

        # Return the archive file path. May be multiple files.
        # eg. containerd may contain containerd, cri-containerd, and cri-containerd-cni
        return $archiveFiles
    }

    end {
        [Logger]::Info("File download and verification process completed.")
    }
}

function Test-CheckSum {
    param(
        [Parameter(Mandatory, ParameterSetName = 'Default')]
        [Parameter(Mandatory, ParameterSetName = 'JSON')]
        [ValidateNotNullOrEmpty()]
        [string] $DownloadedFile,

        [Parameter(Mandatory, ParameterSetName = 'Default')]
        [Parameter(Mandatory, ParameterSetName = 'JSON')]
        [ValidateNotNullOrEmpty()]
        [string] $ChecksumFile,

        [Parameter(Mandatory, ParameterSetName = 'JSON')]
        [switch]$JSON,

        [Parameter(Mandatory, ParameterSetName = 'JSON')]
        [ValidateNotNullOrEmpty()]
        [string]$SchemaFile,

        [Parameter(ParameterSetName = 'JSON')]
        [ScriptBlock]$ExtractDigestScriptBlock,

        [Parameter(ParameterSetName = 'JSON')]
        [System.Array]$ExtractDigestArguments
    )

    [Logger]::Debug("Checksum verification...`n`tSource file: $DownloadedFile`n`tChecksum file: $ChecksumFile")

    if (-not (Test-Path -Path $downloadedFile)) {
        Throw "Couldn't find source file: `"$downloadedFile`"."
    }

    if (-not (Test-Path -Path $ChecksumFile)) {
        Throw "Couldn't find checksum file: `"$ChecksumFile`"."
    }

    if ($JSON) {
        [Logger]::Debug("Checksum file format: JSON")
        [Logger]::Debug("SchemaFile: $SchemaFile")
        return (
            Test-JSONChecksum `
                -DownloadedFile $downloadedFile `
                -ChecksumFile $ChecksumFile `
                -SchemaFile $SchemaFile `
                -ExtractDigestScriptBlock $ExtractDigestScriptBlock `
                -ExtractDigestArguments $ExtractDigestArguments
        )
    }

    [Logger]::Debug("Checksum file format: Text")
    return Test-FileChecksum -DownloadedFile $DownloadedFile -ChecksumFile $ChecksumFile
}

function Test-FileChecksum {
    # https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/usedeclaredvarsmorethanassignments?view=ps-modules#special-cases
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "isValid", Justification = "Special case")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "found", Justification = "Special case")]

    [OutputType([bool])]
    param(
        [parameter(Mandatory)]
        [string] $DownloadedFile,

        [Parameter(Mandatory)]
        [string] $checksumFile
    )

    # Get download file name from downloaded file
    $downloadedFileName = Split-Path -Leaf $DownloadedFile

    $isValid = $false
    try {
        # Extract algorithm from checksum file name
        if ($checksumFile -notmatch "(?<hashfunction>$HASH_FUNCTIONS_STR)") {
            Throw "Invalid hash function. Supported hash functions: $($HASH_FUNCTIONS -join ', ')"
        }
        $algorithm = $matches.hashfunction
        [Logger]::Debug("Algorithm: $algorithm")
        $downloadedChecksum = Get-FileHash -Path $DownloadedFile -Algorithm $algorithm

        # checksum is stored in a file named SHA256SUMS
        # checksum file content format: <checksum>  <filename>
        #    separate by two spaces
        $found = $false
        Get-Content -Path $checksumFile | ForEach-Object {
            # Split the read line to extract checksum and filename
            if ($_ -notmatch "^([\d\w]+)(\s){1,2}([\S]+)$") {
                Throw "Invalid checksum file content format in $checksumFile. Expected format: <checksum> <filename>."
            }

            # 0: full match, 1: checksum, 2: space, 3: filename
            $checksum = $matches[1]
            $filename = $matches[3]

            # Check if the downloaded file name matches any of the file names in the checksum file
            if ($filename -match "^(?:\.\/release\/)?($downloadedFileName)$") {
                $isValid = $downloadedChecksum.Hash -eq $checksum
                $found = $true
                return
            }
        }

        if (-not $found) {
            Throw "Checksum not found for `"$downloadedFileName`" in $checksumFile"
        }
    }
    catch {
        Throw "Checksum verification failed for $DownloadedFile. $_"
    }
    finally {
        # Delete checksum file
        [Logger]::Debug("Deleting checksum file $checksumFile")
        if (Test-Path -Path $checksumFile) {
            Remove-Item -Path $checksumFile -Force -ErrorAction Ignore
        }
    }

    [Logger]::Debug("Checksum verification status. {success: $isValid}")
    return $isValid
}

function Test-JSONChecksum {
    [OutputType([bool])]
    param(
        [parameter(Mandatory)]
        [string] $DownloadedFile,

        [parameter(Mandatory)]
        [string] $checksumFile,

        [Parameter(Mandatory)]
        [string] $SchemaFile,

        [Parameter(HelpMessage = "Script block to extract checksum from JSON file. If the ScriptBlock takes any parameters, pass them as an object with ``ExtractDigestArguments``. The function must return a FileDigest object with HashFunction (string) and Digest (string).")]
        [ScriptBlock]$ExtractDigestScriptBlock,

        [Parameter(HelpMessage = "Parameters to pass to the script block.")]
        [System.Array]$ExtractDigestArguments
    )

    # Validate the checksum file
    $isJsonValid = ValidateJSONChecksumFile -ChecksumFilePath $checksumFile -SchemaFile $SchemaFile
    [Logger]::Debug("Checksum JSON file validation status. {success: $isJsonValid}")

    if ($null -eq $ExtractDigestScriptBlock) {
        [Logger]::Debug("Using default JSON checksum extraction script block")
        $ExtractDigestScriptBlock = ${function:GenericExtractDigest}
        $ExtractDigestArguments = @($DownloadedFile, $checksumFile)
    }

    # Invoke the script block to extract the file digest
    [Logger]::Debug("Extracting file digest from $checksumFile")
    $extractedFileDigest = & $ExtractDigestScriptBlock @ExtractDigestArguments

    # Since Invoke() returns a collection, we need to extract the first item
    if ( ($null -eq $extractedFileDigest) -or
        ($extractedFileDigest.Count -ne 1) -or
        ($extractedFileDigest[0].GetType().Name -ne "FileDigest")
    ) {
        Throw 'Invalid value. Requires a value with type "FileDigest".'
    }

    # Validate the hash function and checksum
    $isValid = $false
    try {
        $algorithm = $extractedFileDigest[0].HashFunction.ToUpper()
        $digest = $extractedFileDigest[0].Digest

        # Validate the hash function
        if ($HASH_FUNCTIONS -notcontains $algorithm) {
            Throw "Invalid hash function, `"$algorithm`". Supported algorithms are: $($HASH_FUNCTIONS -join ', ')"
        }

        # Validate the checksum
        $hash = Get-FileHash -Path $DownloadedFile -Algorithm $algorithm
        $isValid = ($digest -eq $hash.Hash)
    }
    catch {
        Throw "Checksum verification failed for $downloadedFile. $_"
    }
    finally {
        # Delete checksum checksumFile
        [Logger]::Debug("Deleting checksum file $checksumFile")
        if (Test-Path -Path $checksumFile) {
            Remove-Item -Path $checksumFile -Force -ErrorAction Ignore
        }
    }

    [Logger]::Debug("Checksum verification status. {success: $isValid}")
    return $isValid
}

function ValidateJSONChecksumFile {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Downloaded checksum file path")]
        [String]$ChecksumFilePath,
        [parameter(Mandatory = $true, HelpMessage = "JSON schema file path")]
        [String]$SchemaFile
    )

    [Logger]::Debug("Validating JSON checksum file...`n`tChecksum file path: $ChecksumFilePath`n`tSchema file: $SchemaFile")

    # Check if the schema file exists
    if (-not (Test-Path -Path $SchemaFile)) {
        Throw "Couldn't find the JSON schema file: `"$SchemaFile`"."
    }

    $schemaFileContent = Get-Content -Path $SchemaFile -Raw
    if ([string]::IsNullOrWhiteSpace($schemaFileContent)) {
        Throw "Invalid schema file: $SchemaFile. Schema file is empty."
    }

    # Test JSON checksum file is valid
    try {
        $isValidJSON = Test-Json -Json "$(Get-Content -Path $ChecksumFilePath -Raw)" -Schema "$schemaFileContent"
        return $isValidJSON
    }
    catch {
        Throw "Invalid JSON format in checksum file. $_"
    }
}

function GenericExtractDigest {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Downloaded tool file path")]
        [String]$DownloadedFile,

        [parameter(Mandatory = $true, HelpMessage = "Downloaded checksum file path")]
        [String]$ChecksumFile
    )

    [Logger]::Debug("Extracting digest from $checksumFile using default script block for in-toto SBOM format")

    # Read the JSON file and get the checksum
    $jsonContent = Get-Content -Path $ChecksumFile -Raw | ConvertFrom-Json

    # Check if using in-toto SBOM format: https://github.com/in-toto/attestation/tree/v0.1.0/spec#statement
    if ($jsonContent._type -notlike "https://in-toto.io/*") {
        Throw( -join (
                "Invalid checksum JSON format. Expected in-toto SBOM format: $($jsonContent._type). ",
                "Please provide an appropriate script block to extract the digest for $($jsonContent._type) format."))
        return
    }

    # Check if the downloaded filename is the same as subject.name
    $downloadedFileName = Split-Path "$DownloadedFile" -Leaf
    for ($i = 0; $i -lt $jsonContent.subject.Count; $i++) {
        $subject = $jsonContent.subject[$i]

        if ($subject.name -ne $downloadedFileName) {
            continue
        }

        $digest = $subject.digest
        $algorithm = ($digest | Get-Member -MemberType NoteProperty).Name
        $checksum = $digest.$algorithm

        return ([FileDigest]::new($algorithm, $checksum))
    }

    Throw "Downloaded file name does not match the subject name ($($subject.name)) in the JSON file."
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
        [string[]] $SourceFile,
        [string] $EnvPath,
        [boolean] $cleanup,

        # Use by WinCNI plugin to avoid updating the environment path
        [boolean] $UpdateEnvPath = $true
    )
    # Create the directory to untar to
    [Logger]::Info("Extracting $Feature to $InstallPath")
    if (!(Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
    }

    # Untar file
    $failed = @()
    foreach ($file in $SourceFile) {
        if (-not (Test-Path -Path $file)) {
            Throw "Couldn't find source file: `"$file`"."
        }

        [Logger]::Debug("Expand archive:`n`tSource file: $file`n`tDestination Path: $InstallPath")
        $cmdOutput = Invoke-ExecutableCommand -executable "tar.exe" -arguments "-xf `"$file`" -C `"$InstallPath`"" -timeout  (60 * 2)
        if ($cmdOutput.ExitCode -ne 0) {
            [Logger]::Error("Failed to expand archive `"$file`" at `"$InstallPath`". Exit code: $($cmdOutput.ExitCode). $($cmdOutput.StandardError.ReadToEnd())")
            $failed += $file
        }
    }

    if ($failed) {
        Throw "Couldn't expand archive file(s) $($failed -join ','). See logs for detailed error information."
    }

    # Add to env path
    if ($UpdateEnvPath -and -not [string]::IsNullOrWhiteSpace($envPath)) {
        Add-FeatureToPath -Feature $feature -Path $envPath
    }

    # Clean up
    if ($CleanUp) {
        [Logger]::Info("Cleanup to remove downloaded files")
        if (Test-Path -Path $SourceFile -ErrorAction SilentlyContinue) {
            Remove-Item -Path $SourceFile -Force -ErrorAction Ignore
        }
    }
}

function Add-FeatureToPath ($Path, $Feature) {
    @("User", "System") | ForEach-Object { Update-EnvironmentPath -Tool $Feature -Path $Path -Action 'Add' -PathType $_ }
}

function Remove-FeatureFromPath {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [string]$Feature
    )

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "$feature will be removed from Environment paths")) {
            @("User", "System") | ForEach-Object { Update-EnvironmentPath -Tool $Feature -Action 'Remove' -PathType $_ }
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

function Test-ServiceRegistered ($service) {
    $scQueryResult = (sc.exe query $service) | Select-String -Pattern "SERVICE_NAME: $service"
    return ($null -ne $scQueryResult)
}

function Invoke-ServiceAction ($Action, $service) {
    if (!(Test-ServiceRegistered -Service $service)) {
        throw "$service service does not exist as an installed service."
    }

    $serviceInfo = Get-Service $service -ErrorAction Ignore
    if (!$serviceInfo) {
        Throw "$service service does not exist as an installed service."
    }

    switch ($Action) {
        'Start' {
            Invoke-StartService -Service $service
        }
        'Stop' {
            Invoke-StopService -Service $service
        }
        Default {
            Throw 'Not implemented'
        }
    }
}

function Invoke-StartService($service) {
    process {
        try {
            Start-Service -Name $service

            # Waiting for the service to come to a steady state
            (Get-Service -Name $service -ErrorAction Ignore).WaitForStatus('Running', '00:00:30')

            [Logger]::Debug("Success: { Service: $service, Action: 'Start' }")
        }
        catch {
            Throw "Couldn't start $service service. $_"
        }
    }
}

function Invoke-StopService($service) {
    process {
        try {
            Stop-Service -Name $service -NoWait -Force

            # Waiting for the service to come to a steady state
            (Get-Service -Name $service -ErrorAction Ignore).WaitForStatus('Stopped', '00:00:30')

            [Logger]::Debug("Success: { Service: $service, Action: 'Stop' }")
        }
        catch {
            Throw "Couldn't stop $service service. $_"
        }
    }
}

function Test-ConfFileEmpty($Path) {
    if (!(Test-Path -LiteralPath $Path)) {
        return $true
    }

    $isFileNotEmpty = (([System.IO.File]::ReadAllText($Path)) -match '\S')
    return (-not $isFileNotEmpty )
}

function Uninstall-ProgramFiles($path) {
    try {
        Get-Item -Path "$path" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    }
    catch {
        $errMsg = $_
        if ($errMsg -match "denied") {
            [Logger]::Error("Failed to delete directory: '$path'. Access to path denied. To resolve this issue, see https://github.com/microsoft/containers-toolkit/blob/main/docs/docs/FAQs.md#resolving-uninstallation-error-access-to-path-denied")
        }
        else {
            [Logger]::Error("Failed to delete directory: '$path'. $_")
        }
    }
}

function Invoke-ExecutableCommand {
    [OutputType([System.Diagnostics.Process])]
    param (
        [parameter(Mandatory)]
        [String] $executable,
        [parameter(Mandatory)]
        [String] $arguments,
        [Parameter(Mandatory = $false, HelpMessage = "Period of time to wait (in seconds) for the associated process to exit. Default is 15 seconds.")]
        [Int32] $timeout = 15
    )

    [Logger]::Debug("Executing '$executable $arguments'")

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $executable
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    # Blocks the current thread of execution until the time has elapsed or the process has exited.
    $p.WaitForExit($timeout * 1000) | Out-Null

    if (-not $p.HasExited) {
        [Logger]::Debug("Execution did not complete in $timeout seconds.")
    }
    else {
        [Logger]::Debug("Command execution completed. Exit code: $($p.ExitCode)")
    }

    return $p
}

Export-ModuleMember -Variable CONTAINERD_REPO, BUILDKIT_REPO, NERDCTL_REPO, WINCNI_PLUGIN_REPO, CLOUDNATIVE_CNI_REPO
Export-ModuleMember -Function Get-LatestToolVersion
Export-ModuleMember -Function Get-DefaultInstallPath
Export-ModuleMember -Function Test-EmptyDirectory
Export-ModuleMember -Function Get-InstallationFile
Export-ModuleMember -Function Install-RequiredFeature
Export-ModuleMember -Function Invoke-ExecutableCommand
Export-ModuleMember -Function Test-ServiceRegistered
Export-ModuleMember -Function Add-FeatureToPath
Export-ModuleMember -Function Remove-FeatureFromPath
Export-ModuleMember -Function Invoke-ServiceAction
Export-ModuleMember -Function Test-ConfFileEmpty
Export-ModuleMember -Function Uninstall-ProgramFiles
Export-ModuleMember -Function Test-CheckSum
Export-ModuleMember -Variable Log
