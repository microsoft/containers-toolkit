###########################################################################
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

class FileDigest {
    [string]$HashFunction
    [string]$Digest

    FileDigest([string]$hashFunction, [string]$digest) {
        $this.HashFunction = $hashFunction
        $this.Digest = $digest
    }
}

Add-Type @'
public enum ActionConsent {
    Yes = 0,
    No = 1
}
'@

$VALID_HASH_FUNCTIONS = @("SHA1", "SHA256", "SHA384", "SHA512", "MD5")


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

function Get-InstallationFile {
    param(
        [parameter(Mandatory, HelpMessage = "Files to download")]
        [PSCustomObject[]] $Files
    )

    begin {
        $functions = {
            function Receive-File ($feature) {
                Write-Information -InformationAction Continue -MessageData "Downloading $($feature.Feature) version v$($feature.Version)"
                try {
                    Invoke-WebRequest -Uri $feature.Uri -OutFile $feature.DownloadPath -UseBasicParsing
                }
                catch {
                    Throw "$($feature.feature) downlooad failed: $($feature.uri).`n$($_.Exception.Message)"
                }
            }
        }
        . $functions
        $jobs = @()
    }

    process {
        # Download file from repo
        if ($Files.Length -eq 1) {
            Receive-File -feature $Files[0]
        }
        else {
            # Import ThreadJob module if not available
            if (!(Get-Module -ListAvailable -Name ThreadJob)) {
                Write-Information -InformationAction Continue -MessageData "Installing module ThreadJob from PowerShell Gallery."
                Install-Module -Name ThreadJob -Scope CurrentUser -Force
            }
            Import-Module -Name ThreadJob -Force

            # Download files asynchronously
            Write-Information -InformationAction Continue -MessageData "Downloading $($Files.Length) container tools executables. This may take a few minutes."

            # Create multiple thread jobs to download multiple files at the same time.
            foreach ($file in $files) {
                $jobs += Start-ThreadJob -Name $file.DownloadPath -InitializationScript $functions -ScriptBlock { Receive-File -Feature $using:file }
            }

            Wait-Job -Job $jobs | Out-Null

            foreach ($job in $jobs) {
                Receive-Job -Job $job | Out-Null
            }
        }
    }

    end {
        $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
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
        [string] $ChecksumUri,

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

    Write-Debug "Checksum verification for $downloadedFile"
    Write-Debug "Checksum URI: $ChecksumUri"

    if (-not (Test-Path -Path $downloadedFile)) {
        Throw "Downloaded file not found: $downloadedFile"
    }

    if ($JSON) {
        Write-Debug "Checksum file format: JSON"
        Write-Debug "SchemaFile: $SchemaFile"
        return (
            Test-JSONChecksum `
                -DownloadedFile $downloadedFile `
                -ChecksumUri $ChecksumUri `
                -SchemaFile $SchemaFile `
                -ExtractDigestScriptBlock $ExtractDigestScriptBlock `
                -ExtractDigestArguments $ExtractDigestArguments
        )
    }

    Write-Debug "Checksum file format: Text"
    return Test-FileChecksum -DownloadedFile $DownloadedFile -ChecksumUri $ChecksumUri
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
        [string] $ChecksumUri
    )

    # Download checksum file
    $downloadDirPath = Split-Path -Parent $DownloadedFile
    $checksumFile = DownloadCheckSumFile -DownloadPath $downloadDirPath -ChecksumUri $ChecksumUri

    Write-Debug "Checksum file: $checksumFile"

    # Get download file name from downloaded file
    $downloadedFileName = Split-Path -Leaf $DownloadedFile

    $isValid = $false
    try {
        # Extract algorithm from checksum file name
        if ($checksumFile -notmatch "($($VALID_HASH_FUNCTIONS -join "|"))") {
            Throw "Invalid hash function. Supported hash functions: $($VALID_HASH_FUNCTIONS -join ', ')"
        }
        $algorithm = $matches[1]
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
        Write-Debug "Deleting checksum file $checksumFile"
        Remove-Item -Path $checksumFile -Force
    }

    Write-Debug "Checksum verification status. {success: $isValid}"
    return $isValid
}

function Test-JSONChecksum {
    [OutputType([bool])]
    param(
        [parameter(Mandatory)]
        [string] $DownloadedFile,

        [parameter(Mandatory)]
        [string] $ChecksumUri,

        [Parameter(Mandatory)]
        [string] $SchemaFile,

        [Parameter(HelpMessage = "Script block to extract checksum from JSON file. If the ScriptBlock takes any parameters, pass them as an object with ``ExtractDigestArguments``. The function must return a FileDigest object with HashFunction (string) and Digest (string).")]
        [ScriptBlock]$ExtractDigestScriptBlock,

        [Parameter(HelpMessage = "Parameters to pass to the script block.")]
        [System.Array]$ExtractDigestArguments
    )

    # Download checksum file
    $downloadDirPath = Split-Path -Parent $DownloadedFile
    $checksumFile = DownloadCheckSumFile -DownloadPath $downloadDirPath -ChecksumUri $ChecksumUri

    # Validate the checksum file
    $isJsonValid = ValidateJSONChecksumFile -ChecksumFilePath $checksumFile -SchemaFile $SchemaFile
    Write-Debug "Checksum JSON file validation status. {success: $isJsonValid}"

    if ($null -eq $ExtractDigestScriptBlock) {
        Write-Debug "Using default JSON checksum extraction script block"
        $ExtractDigestScriptBlock = ${function:GenericExtractDigest}
        $ExtractDigestArguments = @($DownloadedFile, $checksumFile)
    }

    # Invoke the script block to extract the file digest
    Write-Debug "Extracting file digest from $checksumFile"
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
        if ($VALID_HASH_FUNCTIONS -notcontains $algorithm) {
            Throw "Invalid hash function, `"$algorithm`". Supported algorithms are: $($VALID_HASH_FUNCTIONS -join ', ')"
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
        Write-Debug "Deleting checksum file $checksumFile"
        Remove-Item -Path $checksumFile -Force
    }

    Write-Debug "Checksum verification status. {success: $isValid}"
    return $isValid
}

function DownloadCheckSumFile {
    [OutputType([string])]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Downloaded file path")]
        [String]$DownloadPath,

        [parameter(Mandatory = $true, HelpMessage = "Checksum URI")]
        [String]$ChecksumUri
    )

    # Get checksum file name
    $OutFile = Join-Path -Path $DownloadPath -ChildPath ($checksumUri -split '/' | Select-Object -Last 1)

    # Download checksum file
    Write-Debug "Downloading checksum file from $checksumUri"
    try {
        Invoke-WebRequest -Uri $checksumUri -OutFile $OutFile -UseBasicParsing
    }
    catch {
        Throw "Checksum file download failed: $checksumUri.`n$($_.Exception.Message)"
    }

    return $OutFile
}

function ValidateJSONChecksumFile {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Downloaded checksum file path")]
        [String]$ChecksumFilePath,
        [parameter(Mandatory = $true, HelpMessage = "JSON schema file path")]
        [String]$SchemaFile
    )

    # Check if the schema file exists
    if (-not (Test-Path -Path $SchemaFile)) {
        Throw "Couldn't find the provided schema file: $SchemaFile"
    }

    $schemaFileContent = Get-Content -Path $SchemaFile -Raw
    if ([string]::IsNullOrWhiteSpace($schemaFileContent)) {
        Throw "Invalid schema file: $SchemaFile. Schema file is empty."
    }

    # Test JSON checksum file is valid
    try {
        Write-Debug "Validating checksum JSON file $checksumFilePath"
        return (Test-Json -Path "$checksumFilePath" -SchemaFile $SchemaFile)
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

    Write-Debug "Extracting digest from $checksumFile using default script block for in-toto SBOM format"

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

            Write-Debug "Success: { Service: $service, Action: 'Start' }"
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

            Write-Debug "Success: { Service: $service, Action: 'Stop' }"
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
            Write-Error "Failed to delete directory: '$path'. Access to path denied. To resolve this issue, see https://github.com/microsoft/containers-toolkit/blob/main/docs/docs/FAQs.md#resolving-uninstallation-error-access-to-path-denied"
        }
        else {
            Write-Error "Failed to delete directory: '$path'. $_"
        }
    }
}

function Invoke-ExecutableCommand {
    param (
        [parameter(Mandatory)]
        [String] $executable,
        [parameter(Mandatory)]
        [String] $arguments,
        [Parameter(Mandatory = $false, HelpMessage = "Period of time to wait (in seconds) for the associated process to exit. Default is 15 seconds.")]
        [Int32] $timeout = 15
    )

    Write-Debug "Executing '$executable $arguments'"

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
        Write-Debug "Execution did not complete in $timeout seconds."
    }
    else {
        Write-Debug "Command execution completed. Exit code: $($p.ExitCode)"
    }

    return $p
}


Export-ModuleMember -Variable VALID_HASH_FUNCTIONS
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
