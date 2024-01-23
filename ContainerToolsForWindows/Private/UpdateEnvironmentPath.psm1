function Update-EnvironmentPath {
    param (
        [parameter(HelpMessage = "Name of the tool add or remove from env path")]
        [string] $Tool,

        [parameter(HelpMessage = "Path of the tool to add or remove from env path")]
        [string] $Path,

        [ValidateSet("System", "User")]
        [parameter(HelpMessage = "Path to change: System or User")]
        [string]$PathType,

        [ValidateSet("Add", "Remove")]
        [parameter(HelpMessage = "Action: Add or Remove the feature path from the environment")]
        [string] $Action
    )

    # Get current environment path
    $parsedPathString = switch ($PathType) {
        "System" {
            $pathVariable = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
            ParsePathString -PathString $pathVariable
        }
        "User" {
            ParsePathString -PathString $env:Path
        }
        Default { throw "Invalid PathType: $PathType" }
    }

    # Check if the path needs to be changed
    switch ($Action) {
        "Add" {
            $pathChanged = $parsedPathString -notlike "*$Tool*"
            $toAction = $Path
            $ActionVerb = "Adding"
        }
        "Remove" {
            $pathChanged = $parsedPathString -like "*$Tool*"
            $toAction = $Tool
            $ActionVerb = "Removing"
        }
        Default { throw "Invalid PathType: $PathType" }
    }

    if ($pathChanged) {
        Write-Information -InformationAction Continue -MessageData "$ActionVerb $toAction in $PathType Environment Path"

        # Get the updated path
        $updatedPath = switch ($Action) {
            "Add" { AddFeatureToPath -PathString $parsedPathString -ToolPath $Path }
            "Remove" { RemoveFeatureFromPath -PathString $parsedPathString -Tool $Tool }
            Default { throw "Invalid Action: $Action" }
        }

        # For tests, we do not want to update the environment path
        if ($env:pester) {
            Write-Debug "Skipping environment path update for tests"
            return $updatedPath
        }

        # Update the environment path
        switch ($PathType) {
            "System" {
                [System.Environment]::SetEnvironmentVariable("Path", "$updatedPath", [System.EnvironmentVariableTarget]::Machine)
            }
            "User" {
                $env:Path = $updatedPath
            }
            Default {
                throw"Invalid PathType: $PathType"
            }
        }
    }
}

function ParsePathString($PathString) {
    $parsedString = $PathString -split ";" | `
        ForEach-Object { $_.TrimEnd("\") } | `
        Select-Object -Unique | `
        Where-Object { ![string]::IsNullOrWhiteSpace($_) }

    if ($null -eq $parsedString) {
        Throw 'Env path cannot be null or an empty string'
    }
    return $parsedString -join ";"
}

function AddFeatureToPath ($PathString, $ToolPath) {
    if (!$PathString) {
        Throw 'Env path cannot be null or an empty string'
    }
    return "$PathString;$ToolPath"
}

function RemoveFeatureFromPath ($PathString, $Tool) {
    $pathString = ParsePathString -Path $pathString
    $parsedString = $pathString -split ";" |  Where-Object { ($_ -notlike "*$tool*") }

    if (!$parsedString) {
        Throw 'Env path cannot be null or an empty string'
    }
    return $parsedString -join ";"
}


Export-ModuleMember -Function Update-EnvironmentPath
