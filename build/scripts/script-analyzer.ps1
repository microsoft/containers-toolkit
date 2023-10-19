$ErrorActionPreference = 'Stop'

if (!(Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
}
Import-Module -Name PSScriptAnalyzer -Force

$codeAnalysis = Invoke-ScriptAnalyzer -Path .\ContainerToolsForWindows\ -Recurse -ExcludeRule PSProvideCommentHelp

$lintIssues = $codeAnalysis | Where-Object { $_.Severity -notlike 'Error' }
if ($lintIssues) {
    Write-Warning "$($lintIssues.Count) lint issues found"
    $lintIssues
}

$lintErrors = $codeAnalysis | Where-Object { $_.Severity -like '*Error' }
if ($lintErrors) {
    $lintErrors
    Throw "$($lintErrors.Count) lint errors found"
}
