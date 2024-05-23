# CONTAINERS TOOLKIT POWERSHELL MODULE

[![CI Build][ci-build-image]][ci-build-site]
[![DevSkim][devskim-image]][devskim-site]
[![cf-image][]][cf-site]

[ci-build-image]: https://github.com/microsoft/containers-toolkit/actions/workflows/ci-build.yaml/badge.svg
[ci-build-site]: https://github.com/microsoft/containers-toolkit/actions/workflows/ci-build.yaml
[devskim-image]: https://github.com/microsoft/containers-toolkit/actions/workflows/sdl-compliance.yaml/badge.svg
[devskim-site]: https://github.com/microsoft/containers-toolkit/actions/workflows/sdl-compliance.yaml
[cf-image]: https://www.codefactor.io/repository/github/powershell/powershell/badge
[cf-site]: https://www.codefactor.io/repository/github/powershell/powershell

## Table of contents

1. [Introduction](#introduction)
2. [Usage](#usage)
    - [Installing and importing Containers-Toolkit module](#installing-and-importing-containers-toolkit-module)
        - [](#download-source-files)
    - [Command reference](#command-reference)
3. [Important Notes](#important-notes)
4. [Contribution](#contribution)
5. [Related Projects](#related-projects)

## Introduction

Containers-Toolkit is a Windows PowerShell module for downloading, installing, and setting up default configs for Containerd, BuildKit, Windows CNI plugin, and nerdctl.

## Usage

### Installing and importing Containers-Toolkit module

#### Install the module from PowerShell Gallery

> COMING SOON: We are currently working on publishing this module to PS Gallery to make it easier to import the module

#### Download Source files

> Coming soon

#### Clone the repo

**Option 1:**  Clone containers-toolkit into one of the folder locations in the `$env:PSModulePath` environment variable.

1. To get a possible module path:

    ```PowerShell
    $env:PSModulePath -split ";"
    ```

2. Clone the repo

    ```PowerShell
    cd <selected-module-path>
    git clone https://github.com/microsoft/containers-toolkit.git
    ```

3. Import the module

    ```PowerShell
    Import-Module -Name containers-toolkit -Force
    ```

**Option 2:** Clone containers-toolkit to a folder location of choice and add the new module location to the Windows PowerShell module path

1. Clone the repo

    ```PowerShell
    git clone https://github.com/microsoft/containers-toolkit.git
    ```

2. Add the directory to @indows PowerShell module path

    ```PowerShell
    $env:PSModulePath = "$env:PSModulePath;<path-to-module-directory>"
    ```

3. Import the module

    ```PowerShell
    Import-Module -Name containers-toolkit -Force
    ```

### Get the module details

```PowerShell
Get-Help containers-toolkit
```

```PowerShell
Get-Module -Name containers-toolkit
```

### Command reference

1. List of all available commands can be found in the [Command reference](./docs/command-reference.md) section
1. Detailed command reference for each cmdlet can be found in the [About](./docs/About/) section

#### List of available commands

```PowerShell
Get-Command -Module containers-toolkit
```

### Examples

1. Get help for Install-Containerd command

    ```PowerShell
    Get-Help Install-Containerd
    ```

2. List container tools (Containerd, BuildKit, and nerdctl) install status

    ```PowerShell
    Show-ContainerTools
    ```

3. Installs Containerd version 1.7.7 at 'C:\Test\Path\containerd' and adds 'C:\Test\Path\containerd' in the environment path.

    ```powershell
    Install-Containerd -Version "1.7.7" -InstallPath 'C:\Test\Path\Containerd'
    ```

## Important Notes

1. Requires elevated PowerShell to run some commands.

1. To use these tools (Containerd, BuildKit, and nerdctl), ensure that Containers and HyperV Windows features are enabled.

    To get the features to enable, use:

    ```PowerShell
    Get-WindowsOptionalFeature -Online | `
        Where-Object { $_.FeatureName -like 'containers' -or $_.FeatureName -match "Microsoft-Hyper-V(-All)?$" } | `
        Select-Object FeatureName, Possible, State, RestartNeeded
    ```

    To enable a feature:

    ```PowerShell
    Enable-WindowsOptionalFeature -Online -FeatureName '<Feature-Name-Here>' -All -NoRestart
    ```

1. Requires PowerShell modules [HNS](https://www.powershellgallery.com/packages/HNS) and [ThreadJob](https://www.powershellgallery.com/packages/ThreadJob)

## FAQs

1. Error when running Import-Module
    - [Error when running Import-Module](https://vnote42.net/2019/07/30/error-when-running-import-module/)
    - [Unblock a script to run it without changing the execution policy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.4#example-7-unblock-a-script-to-run-it-without-changing-the-execution-policy)
    - [Unblock-File](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file?view=powershell-7.4)

## TODO

- [ ] Set up GitWorkflow files:
  - [GitHub Repository Structure Best Practices](https://medium.com/code-factory-berlin/github-repository-structure-best-practices-248e6effc405)
  - Setup ARM64 [self-hosted runner](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners)
  - Dependabot to update version in main + Licence
- [ ] Pipeline configuration:
  - Code Analysis with [DevSkim](https://aka.ms/DevSkim)
- [ ] Publish module to PSGallery
- [ ] Fix Code analysis warnings
- [ ] Dev install: (Hacks) Add functions in Containerd and BuildKit to build from source files. (Is this really necessary? May be an overkill)
- [ ] Publish to Microsoft Learn: [MicrosoftDocs
/
Virtualization-Documentation](https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/live/virtualization/windowscontainers)
  - [Contribute to the Microsoft Learn platform](https://learn.microsoft.com/en-us/contribute/content/?source=recommendations)
- [x] Rename this module to containerstoolkit: The current name for this module might cause confusion with repository named windows-containers-tools
- [x] Update README.md (Documentation)
- [x] Update containers-toolkit/containers-toolkit.Format.ps1xml (Documentation)
- [x] Update Containers-Toolkit/Containers-ToolkitlsForWindows.help.txt (Documentation)
- [x] Use Containers-Toolkit
- [x] Add Pester test
- [x] Replace GitHub username in URL: <https://github.com/...>
- [ ] ~~Rootless installation~~: Not needed for Windows

## Contribution

## Related Projects

This project builds on work done by others to create a PowerShell module.

- [Install-ContainerdRuntime](https://github.com/microsoft/Windows-Containers/blob/Main/helpful_tools/Install-ContainerdRuntime/install-containerd-runtime.ps1)
- [sig-windows-tools- Install-Containerd.ps1](https://github.com/kubernetes-sigs/sig-windows-tools/blob/master/hostprocess/Install-Containerd.ps1)
- [containerd-installer](https://github.com/lippertmarkus/containerd-installer)
- [Install MCR on Windows Servers](https://docs.mirantis.com/mcr/20.10/install/mcr-windows.html)
- [Stevedore](https://github.com/slonopotamus/stevedore)
- [setup_buildkitd_on_windows.ps1](https://gist.github.com/gabriel-samfira/6e56238ad11c24f490ac109bdd378471)
- [Windows Containers on Windows 10 without Docker (using Containerd)](https://www.jamessturtevant.com/posts/Windows-Containers-on-Windows-10-without-Docker-using-Containerd/)

## Other relevant repositories

- [Containerd](https://github.com/containerd/containerd)
- [BuildKit](https://github.com/moby/buildkit)
- [nerdctl](https://github.com/containerd/nerdctl)
- [Container networking plugins for Windows containers](https://github.com/microsoft/windows-container-networking)
