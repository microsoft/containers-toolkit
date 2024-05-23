###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

# $ErrorActionPreference = 'Stop'
function ConvertTo-MarkdownTable {
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$InputObject
    )

    $table = "| Rule Name | Severity | Count |`n| -------- | ------- | ------- |"
    foreach ($object in $InputObject) {
        $count = $object.Count

        $name = $object.Name -split ","
        $severity = $name[0].Trim()
        $ruleName = $name[1].Trim()

        $table += "`n| $ruleName | $severity | $count |"
    }

    return $table
}

function ConvertTo-MarkDown {
    param (
        [PSObject]$InputObject,
        [String]$IssueCountString
    )

    $summary = $InputObject | Group-Object -Property Severity, RuleName -NoElement | Sort-Object Count -Descending
    $table = ConvertTo-MarkdownTable $summary

    return @(
        "### PSSciptAnalysis Report`n"
        "<details>"
        "<summary>"
        ":triangular_flag_on_post: "
        $IssueCountString
        "</summary>`n"
        # blank lines are needed before/after a section of markdown that is within an html tag,
        # otherwise the markdown won't work
        "`n"
        "$table"
        "`n"
        "`n</details>"
    ) -join ' '
}

function main {
    $codeAnalysis = Invoke-ScriptAnalyzer -Path . -Recurse -ExcludeRule PSProvideCommentHelp, PSUseSingularNouns

    $lintIssues = $codeAnalysis | Where-Object { $_.Severity -notlike 'Error' }
    $lintErrors = $codeAnalysis | Where-Object { $_.Severity -like '*Error' }

    $IssueCountString = "$($lintErrors.Count) errors and $($lintIssues.Count) warnings found"
    Write-Warning $IssueCountString

    if ($lintErrors -or $lintIssues) {
        Export-Clixml -Path 'psscriptanalysis.xml' -InputObject $codeAnalysis

        # Convert to markdown
        Write-Output (ConvertTo-MarkDown -InputObject $codeAnalysis -IssueCountString $IssueCountString)
    }
    else {
        Write-Output ":clap: $IssueCountString"
    }

    if ($lintErrors) {
        Throw "$($lintErrors.Count) lint errors found"
    }
}


if (!(Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
}
Import-Module -Name PSScriptAnalyzer -Force

main
