<#
.SYNOPSIS
Runs ContainerToolsForWindows module tests 

.DESCRIPTION
Runs ContainerToolsForWindows module tests.
https://pester.dev/docs/commands/New-PesterConfiguration
https://pester.dev/docs/usage/output

.PARAMETER FileName
Comma-separated list of specific module file (.psm1) in this module to run tests for

.PARAMETER Tag
Comma-separated list of specific commands/functions in this module to run tests for 

.PARAMETER Verbosity
The verbosity of output, options are None, Normal, Detailed and Diagnostic. Default value: 'Detailed'

.EXAMPLE
PS> .\run-tests.ps1 

.EXAMPLE
To run tests for specific functions, provide the name of the cmdlet/function or a comma-separated list:
PS> .\run-tests.ps1 -Local -Tag "Get-LatestToolVersion,Uninstall-Buildkit"

.EXAMPLE
To run tests for specific module file, provide the name of the file or a comma-separated list:
PS> .\run-tests.ps1 -Local -Tag "BuildkitTools.psm1"

.NOTES
    - Set $erroractionPreference = "Continue" to ensure that Write-Error messages are not treated as terminating errors.

#>

#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.5.0" }

using module ..\..\Tests\TestData\MockClasses.psm1

[CmdletBinding()]
param (
    [Parameter(HelpMessage = "Verbosity of output. Default: 'Detailed'")]
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string] $Verbosity = 'Detailed',

    [Parameter(HelpMessage = "Run tests for specific commands/functions")]
    [string] $Tag,

    [Parameter(HelpMessage = "Run tests for a specific module file")]
    [string] $FileName
)
Write-Host "ErrorActionPreference: $ErrorActionPreference" -ForegroundColor DarkCyan

$RootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Write-Host "Root directory: $RootDir" -ForegroundColor DarkCyan

New-Item -Path Env:\Pester -Value $true | Out-Null

########################################################
#################### IMPORT MODULES ####################
########################################################
Write-Host "Importing modules" -ForegroundColor DarkCyan
Import-Module PowerShellGet # Needed to avoid error: "CommandNotFoundException: Could not find Command Install-Module"
Import-Module Pester -Force 

if (!(Get-Module -ListAvailable -Name HNS)) {
    Install-Module -Name HNS -AllowClobber -Force
}
Import-Module -Name HNS -DisableNameChecking -Force
        
if (!(Get-Module -ListAvailable -Name ThreadJob)) {
    Install-Module -Name ThreadJob -Force
}
Import-Module -Name ThreadJob -Force


#######################################################
################### DISCONVER TESTS ###################
#######################################################
Write-Host "Discovering tests" -ForegroundColor DarkCyan
$ModuleParentPath = "$RootDir\ContainerToolsForWindows"
$unitTests = Get-ChildItem -Path "$RootDir\Tests" -Filter "*.tests.ps1" -Recurse
$array = @()

foreach ($unitTest in $unitTests) {
    write-host "Unit tests found in $($unitTest.FullName)"
    $container = New-PesterContainer -Path $unitTest.FullName
    $array += $container
}


#######################################################
################ PESTER CONFIGURATION #################
#######################################################
$config = [PesterConfiguration]::Default
$config.Output.Verbosity = $Verbosity
$config.Filter.Tag = ($tag -split ',')
$config.Filter.FullName = ($FileName -split ',')
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = "NUnitXML"
$config.TestResult.OutputPath = "$RootDir\TestResults\Test-Results.xml"
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.OutputPath = "$RootDir\TestResults\coverage.xml"
$config.CodeCoverage.Path = @( "$ModuleParentPath\Private", "$ModuleParentPath\Public" )
$config.Run.Exit = $False
$config.Run.Container = $array

Invoke-Pester -Configuration $config


######################################################
###################### CLEANUP #######################
######################################################
Remove-Item -Path Env:\Pester -Force
