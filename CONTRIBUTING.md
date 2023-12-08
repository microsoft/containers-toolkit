# Contributing to Containers Toolkit Project

Welcome, and thank you for your interest in contributing to Containers Toolkit.

There are many ways in which you can contribute, beyond writing code. The goal of this document is to provide a high-level overview of how you can get involved. See the [Table of Contents](#table-of-contents) for different ways to help and details about how this project handles them.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Contributor License Agreement](#contributor-license-agreement)
- [Reporting Issues](#reporting-issues)
- [Contributing to Documentation](#contributing-to-documentation)
- [Contributing to Code](#contributing-to-code)
- [Linting](#linting)
- [Testing Guidelines](#testing-guidelines)
- [Recommended Workflow](#recommended-workflow)

## Code of Conduct

This project and everyone participating in it is governed by the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

By participating, you are expected to uphold this code. Please report unacceptable behavior to <opencode@microsoft.com>. For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributor License Agreement

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

## Reporting Issues

This project uses GitHub Issues to track bugs and feature requests. Please search the [existing issues](https://github.com/microsoft/containers-toolkit/issues) before filing new issues to avoid duplicates. If you do find an existing issue, please include your own feedback in the discussion. Do consider upvoting (👍 reaction) the original post, as this helps us prioritize popular issues in our backlog.

For new issues, file your bug or feature request as a [new issue](https://github.com/microsoft/containers-toolkit/issues). Be sure to include as much information as possible to help us understand and reproduce the problem:

- Provide as much context as you can about what you are running into.
- Provide project and platform versions depending on what seems relevant.

If you know how to fix the issue, feel free to send a pull request our way. (This Contribution Guide applies to that pull request, you may want to give it a read!)

### Writing a Good Bug Report

Good bug reports make it easier for maintainers to verify and triage the underlying problem. The better a bug report, the faster the problem will be resolved. Ideally, a bug report should contain the following information:

- A high-level description of the problem.
- A _minimal reproduction_, i.e. the smallest size of code/configuration required to reproduce the wrong behavior.
- A description of the _expected behavior_, contrasted with the _actual behavior_ observed.
- Information on the environment: PowerShell version, container tool version, etc.
- Additional information, e.g. is it a regression from previous versions? are there any known workarounds?

Your question serve as a resource to others searching for help.

## Contributing to Documentation

### Quick steps if you are changing an existing cmdlet

If you made a change to an existing cmdlet and would like to update the documentation using PlatyPS,
here are the quick steps:

1. Install `PlatyPS` if you do not have it - `Install-Module PlatyPS`.
1. Fork the [microsoft/containers-toolkit](https://github.com/Microsoft/containers-toolkit) repository if you do not already have it.
1. Start your local build of PowerShell.
1. Find the [cmdlet's Markdown file](./docs/About/) in Docs. For example: docs/About/Get-BuildkitLatestVersion.md
1. Run `Update-MarkdownHelp -Path <path to cmdlet Markdown file>` which will update the documentation for you.
1. Make any additional changes needed for the cmdlet to be properly documented.
1. Update the module help files:

    ```PowerShell
    Set-Location <repo-location>
    $commandsDir= 'docs\About'
    $enUSDir = 'containers-toolkit\en-US'
    New-ExternalHelp -Path $commandsDir -OutputPath $enUSDir -Force
    ```

1. Create a Pull Request to the [microsoft/containers-toolkit](https://github.com/Microsoft/containers-toolkit) repository with the changes
    - Make sure you squash your commits
    - Sign your commits
1. Link your Docs PR to your original change PR.

### Spellchecking documentation

Documentation is spellchecked. We use the[textlint](https://github.com/textlint/textlint/wiki/Collection-of-textlint-rule) command-line tool,which can be run in interactive mode to correct typos.

To run the spellchecker, follow these steps:

- Install [Node.js](https://nodejs.org/en/) (v10 or up)
- Install [textlint](https://github.com/textlint/textlint/wiki/Collection-of-textlint-rule) by  `npm install -g textlint textlint-rule-spelling dictionary-en`
- Run `npx textlint <changedFileName>`,  adding `--fix` will accept all the recommendations.

If you need to add a term or disable checking part of a file see the [configuration sections of the rule](https://github.com/sapegin/textlint-rule-terminology).

### Checking links in documentation

Documentation is link-checked. We make use of the `markdown-link-check` command-line tool, which can be run to see if any links are dead.

To run the link-checker, follow these steps:

- Install [Node.js](https://nodejs.org/en/) (v10 or up)
- Install `markdown-link-check` by
    `npm install -g markdown-link-check`
- Run `markdown-link-check` on .md files in the project directory.

  ```PowerShell
  Get-ChildItem -Path "README.md",".\docs\" -Filter "*.md" -Recurse | ForEach-Object { & markdown-link-check $_.FullName -q } 
  ```

## Contributing to Code

### Coding guidelines

Please follow the PowerShell [Common Engineering Practices](https://github.com/PowerShell/PowerShell/blob/master/.github/CONTRIBUTING.md#common-engineering-practices).

These is not a comprehensive list, but a high-level guide.

Please do:

- **DO** follow our coding style.
- **DO** include tests when adding new features. When fixing bugs, start with
  adding a test that highlights how the current behavior is broken.
- **DO** keep the discussions focused. When a new or related topic comes up
  it's often better to create a new issue than to side track the discussion.
- **DO** feel free to blog, tweet, or share anywhere else about your contributions!

Please do not:

- **DON'T** make PRs for style changes.
- **DON'T** surprise us with big pull requests. For large changes, create
  a new discussion so we can agree on a direction before you invest a large amount
  of time. For bug fixes, create an issue.
- **DON'T** commit code that you didn't write. If you find code that you think is a good fit to add to any of the tools, file an issue and start a discussion before proceeding.
- **DON'T** submit PRs that alter licensing related files or headers. If you believe there's a problem with them, file an issue and we'll be happy to discuss it.

### New files

- If your change adds a new source file, ensure the appropriate copyright and license headers is on top.
  It is standard practice to have both a copyright and license notice for each source file.

  ```PowerShell
  ###########################################################################
  #                                                                         #
  #   Copyright (c) Microsoft Corporation. All rights reserved.             #
  #                                                                         #
  #   This code is licensed under the MIT License (MIT).                    #
  #                                                                         #
  ###########################################################################
  <Add empty line here>

  <Your code here>
  ```

### Setup development environment

1. **Clone the repo**

    **Option 1:**  Clone containers-toolkit into one of the folder locations in the `$env:PSModulePath` environment variable.

    1. Get a possible module path:

        ```PowerShell
        $env:PSModulePath -split ";"
        ```

    1. Clone the repo

        ```PowerShell
        cd <selected-module-path>
        git clone https://github.com/microsoft/containers-toolkit.git
        ```

    **Option 2:** Clone containers-toolkit to a folder location of choice and add the new module location to the Windows PowerShell module path

    1. Clone the repo

        ```PowerShell
        cd <path-of-your-choice>
        git clone https://github.com/microsoft/containers-toolkit.git
        ```

    1. Add the directory to Windows PowerShell module path

        ```PowerShell
        $env:PSModulePath += ";<path>/containers-toolkit"
        ```

1. **Check the module is imported** in the current session or that can be imported from the PSModulePath

    ```PowerShell
    Get-Module -Name "containers-toolkit" -ListAvailable
    ```

1. **Import the module**

    ```PowerShell
    Import-Module -Name containers-toolkit -Force
    ```

## Linting

To maintain code quality and consistency, we use PowerShell Script Analyzer ([PSScriptAnalyzer](https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/?view=ps-modules)) for linting our scripts. Follow these steps to lint your code before submitting a pull request:

1. **Install PSScriptAnalyzer** (if not already installed):

    ```PowerShell
    Install-Module -Name PSScriptAnalyzer -Force
    ```

2. **Run the linter**:

    Navigate to the root directory of the repository and run the following command:

    ```PowerShell
    Invoke-ScriptAnalyzer -Path . -Recurse -ExcludeRule PSProvideCommentHelp, PSUseSingularNouns
    ```

    - `-Path .` specifies the current directory.
    - `-Recurse` ensures that the linter checks all subdirectories.
    - `-ExcludeRule PSProvideCommentHelp, PSUseSingularNouns` excludes the `PSProvideCommentHelp` and `PSUseSingularNouns` rules from the analysis. We exclude these rules because:
        - `PSProvideCommentHelp`: We might not require comment-based help for every function in the module.
        - `PSUseSingularNouns`: There might be legitimate cases where plural nouns are necessary.

3. **Review and fix issues**:

    Review the output of the linter and fix any issues that are flagged. Ensuring your code passes linting checks helps maintain a high standard of code quality and consistency across the repository.

By following these linting guidelines, you help ensure that your contributions are aligned with the project's coding standards, making it easier for maintainers to review and merge your changes.

## Testing Guidelines

Testing is a critical and required part of this project.

For creating new tests, please review the [Pester documentation](https://pester.dev/docs/quick-start) on how to create tests for PowerShell. There is a best practices document for [writing Pester tests](https://github.com/PowerShell/PowerShell/tree/master/docs/testing-guidelines/WritingPesterTests.md).

### CI System

We use [GitHub Actions workflows](https://docs.github.com/en/actions/using-workflows) as a continuous integration (CI) system for Windows and non-Windows platforms.

In the `README.md` at the top of the repository, you can see CI Build badge.
It indicates the last build status of `master` branch.

This badge is **clickable**; you can open corresponding build page with logs, artifacts, and tests results.
From there you can easily navigate to the build history.

### Test Frameworks

#### Pester

Our script-based test framework is [Pester](https://github.com/Pester/Pester). We recommend adding tests for any new code or code that changes functionality.

**References**

- [`New-PesterConfiguration`](https://pester.dev/docs/commands/New-PesterConfiguration) cmdlet
- [`Invoke-Pester`](https://pester.dev/docs/commands/invoke-pester/) cmdlet
- [`Tag`](https://pester.dev/docs/usage/tags) parameter

#### Running Containers-Toolkit tests outside of CI

During the automated CI the unit tests and integration tests are run as part of the PR validation. You can run these tests locally by using [`Invoke-Pester` cmdlet](https://pester.dev/docs/commands/invoke-pester/) or the [`run-tests.ps1` file](./build/scripts/run-tests.ps1). The [`run-tests.ps1` file](./build/scripts/run-tests.ps1) uses a [PesterConfiguration-object](https://pester.dev/docs/commands/New-PesterConfiguration) for runnings tests using Invoke-Pester.  

> [!TIP]  
> If using `run-tests.ps1`, remember to set `$ErrorActionPreference = "Continue"` to ensure that `Write-Error` messages are not treated as terminating errors.

**Run all tests**

```PowerShell
run-tests.ps1
```

**Run tests for specific function**

To execute tests for a specific method, use `-Tag` parameter. This parameter accepts a string or comma-separated list of specific commands/functions in this module to run tests on. This utilizes the [`Tag` parameter](https://pester.dev/docs/usage/tags) in Pester framework.

```PowerShell
run-tests.ps1 -Tag "Initialize-NatNetwork"
```

**Run tests for specific file**

To execute tests for a specific module files (.psm1), use `-ModuleName` parameter. This parameter accepts a string or a comma-separated list of specific commands or functions in this module to run tests on.

```PowerShell
run-tests.ps1 -ModuleName ContainerNetworkTools.psm1
```

**NOTE:** _The file extension (.psm1) is optional._

**Change verbosity of test output**

To change the verbosity of the output, use `-Verbosity` parameter. Options are None, Normal, Detailed and Diagnostic. Default value: 'Detailed'

```PowerShell
run-tests.ps1 -Verbosity Normal
```

## Recommended Workflow

### Forks and Pull Requests

GitHub fosters collaboration through the notion of [pull requests][using-prs]. On GitHub, anyone can [fork][fork-a-repo] an existing repository into their own user account, where they can make private changes to their fork. To contribute these changes back into the original repository, a user simply creates a pull request in order to "request" that the changes be taken "upstream".

Additional references:

- GitHub's guide on [forking](https://guides.github.com/activities/forking/)
- GitHub's guide on [Contributing to Open Source](https://guides.github.com/activities/contributing-to-open-source/#pull-request)
- GitHub's guide on [Understanding the GitHub Flow](https://guides.github.com/introduction/flow/)

### How to submit pull requests

To make changes to content, submit a pull request (PR) from your fork. Always create a pull request to the master branch of this repository. A pull request must be reviewed before it can be merged. See guide on [how to submit a pull request](https://learn.microsoft.com/en-us/powershell/scripting/community/contributing/pull-requests?view=powershell-7.4).

### Suggested Workflow

We use and recommend the following workflow:

1. Create an issue for your work.
    - You can skip this step for trivial changes.
    - Reuse an existing issue on the topic, if there is one.
    - Get agreement from the team and the community that your proposed change is a good one.
    - Clearly state that you are going to take on implementing it, if that's the case. You can request that the issue be assigned to you. Note: The issue filer and the implementer do not have to be the same person.
1. Create a personal fork of the repository on GitHub (if you do not already have one).
1. In your fork, create a branch off of main (`git checkout -b mybranch`).
    - Name the branch so that it clearly communicates your intentions, such as issue-123 or githubhandle-issue.
    - Branches are useful since they isolate your changes from incoming changes from upstream. They also enable you to create multiple PRs from the same fork.
1. Make and commit your changes to your branch.
1. Add new tests corresponding to your change, if applicable.
1. Build the repository with your changes.
    - Make sure that the builds are clean.
    - Make sure that the tests are all passing, including your new tests.
    - Fix any linting/styling issues.
        Run the [Script Analyzer](#linting)
1. Create a pull request (PR) against the [`microsoft/containers-toolkit`](https://github.com/microsoft/containers-toolkit/compare) repository's **main** branch.
    - State in the description what issue or improvement your change is addressing.
    - Check if all the tests are passing.
1. Wait for feedback or approval of your changes from the team.
1. When the team has signed off, and all checks are green, your PR will be merged.
    - The next official build will include your change.
    - You can delete the branch you used for making the change.

## Attribution

_Parts of the guideline adopted from [PowerShell CONTRIBUTING.md](https://github.com/PowerShell/PowerShell/blob/master/.github/CONTRIBUTING.md) and [.Net Monitor](https://github.com/dotnet/dotnet-monitor/blob/main/CONTRIBUTING.md)._
