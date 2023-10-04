$envPathRegKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

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
    $currPath = ParsePathString($currPath)
    if (!($currPath -like "*$feature*")) {
        Write-Information -InformationAction Continue -MessageData "Adding $feature to Environment Path RegKey"

        # Add to reg key
        Set-ItemProperty -Path $envPathRegKey -Name PATH -Value "$currPath;$path"
    }

    $currPath = ParsePathString($env:Path)
    if (!($currPath -like "*$feature*")) {
        Write-Information -InformationAction Continue -MessageData "Adding $feature to env path"

        # Add to env path
        $env:Path = "$currPath;$path"
    }
}

function Remove-FeatureFromPath {
    param (
        [string]
        [ValidateNotNullOrEmpty()]
        [parameter(HelpMessage = "Feature to remove from env path")]
        $feature
    )
    Write-Information -InformationAction Continue -MessageData "Removing $featurepath from env path"

    # Remove from regkey
    $currPath = (Get-ItemProperty -Path $envPathRegKey -Name path).path
    $currPath = ParsePathString($currPath)
    if ($currPath -like "*$feature*") {
        $NewPath = removeFeatureFromPath($currPath, $feature)
        Set-ItemProperty -Path $envPathRegKey -Name PATH -Value $NewPath
    }

    # Remove from env path
    $currPath = ParsePathString($env:Path)
    if (!($currPath -like "*$feature*")) {
        $env:Path = removeFeatureFromPath($currPath, $feature)
    }
}

function removeFeatureFromPath ($pathString, $feature) {
    $parsedString = $pathString -split ";" | `
        Select-Object -Unique | `
        Where-Object { !($_ -like "*$feature*") }
    return $parsedString -join ";"
}

function ParsePathString($pathString) {
    $parsedString = $pathString -split ";" | `
        Select-Object -Unique | `
        Where-Object { ![string]::IsNullOrWhiteSpace($_) }
    return $parsedString -join ";"
}


Export-ModuleMember -Function Add-FeatureToPath
Export-ModuleMember -Function Remove-FeatureFromPath