# Contributing to Containers Toolkit Project

Welcome, and thank you for your interest in contributing to Containers Toolkit.

There are many ways in which you can contribute, beyond writing code. The goal of this document is to provide a high-level overview of how you can get involved. See the [Table of Contents](#table-of-contents) for different ways to help and details about how this project handles them.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Reporting Issues](#reporting-issues)
  - [Writing a Good Bug Report](#writing-a-good-bug-report)
- [Contributing to Documentation](#contributing-to-documentation)
  - [Quick steps if you're changing an existing cmdlet](#quick-steps-if-you-are-changing-an-existing-cmdlet)
  - [Spellchecking documentation](#spellchecking-documentation)
  - [Checking links in documentation](#checking-links-in-documentation)
- [Contributing to Code](#contributing-to-code)
  - [Coding guidelines](#coding-guidelines)
- [New files](#new-files)
- [Testing Guidelines](#testing-guidelines)
  - [CI System](#ci-system)
  - [Test Frameworks](#test-frameworks)
- [Recommended Workflow](#recommended-workflow)
  - [Forks and Pull Requests](#forks-and-pull-requests)
  - [How to submit pull requests](#how-to-submit-pull-requests)
  - [Suggested Workflow](#suggested-workflow)
- [Contributor License Agreement](#contributor-license-agreement)

## Code of Conduct

This project and everyone participating in it is governed by the [Microsoft Open Source Code of Conduct
](./CODE-OF-CONDUCT.md).
By participating, you are expected to uphold this code. Please report unacceptable behavior to <opencode@microsoft.com>.

## Reporting Issues

Before filing a new issue, please search our [open issues](https://github.com/microsoft/windows-container-tools/issues) to check if it already exists. If you do find an existing issue, please include your own feedback in the discussion. Do consider upvoting (👍 reaction) the original post, as this helps us prioritize popular issues in our backlog.

If you cannot find your issue already, [open a new issue](/issues/new).

- Provide as much context as you can about what you are running into.
- Provide project and platform versions depending on what seems relevant.

If you know how to fix the issue, feel free to send a pull request our way. (This Contribution Guide applies to that pull request, you may want to give it a read!)

### Writing a Good Bug Report

Good bug reports make it easier for maintainers to verify and triage the underlying problem. The better a bug report, the faster the problem will be resolved. Ideally, a bug report should contain the following information:

- A high-level description of the problem.
- A _minimal reproduction_, i.e. the smallest size of code/configuration required to reproduce the wrong behavior.
- A description of the _expected behavior_, contrasted with the _actual behavior_ observed.
- Information on the environment: PowerShell version, package version, etc.
- Additional information, e.g. is it a regression from previous versions? are there any known workarounds?

Your question serve as a resource to others searching for help.

## Contributing to Documentation

### Quick steps if you are changing an existing cmdlet

If you made a change to an existing cmdlet and would like to update the documentation using PlatyPS,
here are the quick steps:

1. Install `PlatyPS` if you do not have it - `Install-Module PlatyPS`.
1. Clone the [Microsoft/containers-toolkits](https://github.com/Microsoft/containers-toolkit) repository if you do not already have it.
1. Start your local build of PowerShell
(with the change to the cmdlet you made).
1. Find the [cmdlet's Markdown file](../About/) in Docs. For example: docs\About\Get-BuildkitLatestVersion.md
1. Run `Update-MarkdownHelp -Path <path to cmdlet Markdown file>` which will update the documentation for you.
1. Make any additional changes needed for the cmdlet to be properly documented.
1. Update the module help files:

        ```PowerShell
        Set-Location <repo-location>
        $commandsDir= 'docs\About'
        $enUSDir = 'ContainerToolsForWindows\en-US'
        New-ExternalHelp -Path $commandsDir -OutputPath $enUSDir -Force
        ```

1. Create a Pull Request to the [Microsoft/containers-toolkits](https://github.com/Microsoft/containers-toolkit) repository with the changes
        - Make sure you squash your commits
        - Sign your commits
1. Link your Docs PR to your original change PR.

### Spellchecking documentation

Documentation is spellchecked. We use the[textlint](https://github.com/textlint/textlint/wiki/Collection-of-textlint-rule) command-line tool,which can be run in interactive mode to correct typos.

To run the spellchecker, follow these steps:

- install [Node.js](https://nodejs.org/en/) (v10 or up)
- install [textlint](https://github.com/textlint/textlint/wiki/Collection-of-textlint-rule) by  `npm install -g textlint textlint-rule-terminology`
- run `textlint --rule terminology <changedFileName>`,  adding `--fix` will accept all the recommendations.

If you need to add a term or disable checking part of a file see the [configuration sections of the rule](https://github.com/sapegin/textlint-rule-terminology).

### Checking links in documentation

Documentation is link-checked. We make use of the `markdown-link-check` command-line tool, which can be run to see if any links are dead.

To run the link-checker, follow these steps:

- install [Node.js](https://nodejs.org/en/) (v10 or up)
- install `markdown-link-check` by
    `npm install -g markdown-link-check@3.8.5`
- run `find . \*.md -exec markdown-link-check {} \;`

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
  - For `.h`, `.cpp`, and `.cs` files use the copyright header with empty line after it:

    ```c#
    // Copyright (c) Microsoft Corporation.
    // Licensed under the MIT License.
    <Add empty line here>
    ```

  - For `.ps1` and `.psm1` files use the copyright header with empty line after it:

    ```PowerShell
    # Copyright (c) Microsoft Corporation.
    # Licensed under the MIT License.
    <Add empty line here>
    ```

## Testing Guidelines

Testing is a critical and required part of this project.

For creating new tests, please review the [Pester documentation](https://pester.dev/docs/quick-start) on how to create tests for PowerShell. There is a best practices document for [writing Pester tests](https://github.com/PowerShell/PowerShell/tree/master/docs/testing-guidelines/WritingPesterTests.md).

### CI System

We use [Azure DevOps](https://azure.microsoft.com/en-us/solutions/devops) as a continuous integration (CI) system for Windows and non-Windows platforms.

In the `README.md` at the top of the repository, you can see Azure CI badge.
It indicates the last build status of `master` branch.

This badge is **clickable**; you can open corresponding build page with logs, artifacts, and tests results.
From there you can easily navigate to the build history.

### Test Frameworks

##### Pester

Our script-based test framework is [Pester](https://github.com/Pester/Pester). We recommend adding tests for any new code or code that changes functionality.

##### Test Tags

The Pester framework allows `Context` blocks to be tagged. Any new Pester  `Context` added must contain the name of the function it tests. Example:

``` PowerShell
# File1.ps1

function Get-Something { }
```

``` PowerShell
# File1.Tests.ps1

Describe "File1.ps1" { # The name of the file/module being tested
    Context "Get-Something" -Tag "Get-Something" {
        It "Should do nothing" {
            $a = 1
            $a | Should -Be 1
        }
    }
}
```

##### Running tests outside of CI

We run the tests using the [run-tests.ps1](.\build\scripts\run-tests.ps1) script.

**Run all tests**

```PowerShell
Set-Location <repo-location>

.\build\scripts\run-tests.ps1

```

**Run tests for specific file**

```PowerShell
Set-Location <repo-location>

.\build\scripts\run-tests.ps1 -File AllToolsUtilities.ps1

```

**Run tests for specific function**

```PowerShell
Set-Location <repo-location>

.\build\scripts\run-tests.ps1 -Tag Install-Nerdctl

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
        Run the [Code Analyser script](../../build/scripts/script-analyzer.ps1)
1. Create a pull request (PR) against the [`microsoft/containers-toolkit`](https://github.com/microsoft/containers-toolkit/compare) repository's **main** branch.
    - State in the description what issue or improvement your change is addressing.
    - Check if all the tests are passing.
1. Wait for feedback or approval of your changes from the team.
1. When the team has signed off, and all checks are green, your PR will be merged.
    - The next official build will include your change.
    - You can delete the branch you used for making the change.

## Contributor License Agreement

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

## Attribution

_*Parts of the guideline adopted from [PowerShell CONTRIBUTING.md](https://github.com/PowerShell/PowerShell/blob/master/.github/CONTRIBUTING.md) and [.Net Monitor](https://github.com/dotnet/dotnet-monitor/blob/main/CONTRIBUTING.md)_
