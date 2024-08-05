# CONTAINERS TOOLKIT POWERSHELL MODULE

[![CI Build][ci-build-image]][ci-build-site]
[![DevSkim][devskim-image]][devskim-site]
[![cf-image][]][cf-site]

[ci-build-image]: https://github.com/microsoft/containers-toolkit/actions/workflows/ci-build.yaml/badge.svg
[ci-build-site]: https://github.com/microsoft/containers-toolkit/actions/workflows/ci-build.yaml
[devskim-image]: https://github.com/microsoft/containers-toolkit/actions/workflows/sdl-compliance.yaml/badge.svg
[devskim-site]: https://github.com/microsoft/containers-toolkit/actions/workflows/sdl-compliance.yaml
[cf-image]: https://www.codefactor.io/repository/github/microsoft/containers-toolkit/badge/main
[cf-site]: https://www.codefactor.io/repository/github/microsoft/containers-toolkit/overview/main

## Table of contents

1. [Introduction](#introduction)
1. [Usage](#usage)
    - [Installing and importing Containers-Toolkit module](#installing-and-importing-containers-toolkit-module)
    - [Command reference](#command-reference)
1. [Important Notes](#important-notes)
1. [FAQs](#faqs)
1. [Contribution](#contribution)
1. [Related Projects](#related-projects)

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

1. **To get a possible module path:**

    ```PowerShell
    $env:PSModulePath -split ";"
    ```

1. **Clone the repo**

    ```PowerShell
    cd <selected-module-path>
    git clone https://github.com/microsoft/containers-toolkit.git
    ```

1. **Import the module**

    ```PowerShell
    Import-Module -Name containers-toolkit -Force
    ```

**Option 2:** Clone containers-toolkit to a folder location of choice and add the new module location to the Windows PowerShell module path

1. **Clone the repo**

    ```PowerShell
    git clone https://github.com/microsoft/containers-toolkit.git
    ```

1. **Add the directory to Windows PowerShell module path**

    ```PowerShell
    $env:PSModulePath += ";<path-to-module-directory>"
    ```

1. **Install module dependencies**
   - Install `ThreadJob` module

    ```powershell
    Install-Module -Name ThreadJob -Force
    ```

    - Install `HNS` module

        To install the HNS module. follow the instructions here [instructions](./docs/FAQs.md#2-new-hnsnetwork-command-does-not-exist)

1. **Import the module**

    ```PowerShell
    Import-Module -Name containers-toolkit -Force
    ```

### Get the module details

```PowerShell
Get-Help containers-toolkit
```

```PowerShell
Get-Module -Name containers-toolkit -ListAvailable
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

See [FAQs.md](./docs/FAQs.md)

## Contribution

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## Related Projects

This project builds on the work of others to create a PowerShell module.

Credits (in alphabetic order):

| Repo/ Author                       | Link                                                                                                                                                                          |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Anthony Nandaa (@profnandaa)       | [cni-setup-legacy.ps1](https://gist.github.com/profnandaa/33d65d85964181a42539bfd0b4f9561a)                                                                                   |
| Gabriel Samfira (@gabriel-samfira) | [setup_buildkitd_on_windows.ps1](https://gist.github.com/gabriel-samfira/6e56238ad11c24f490ac109bdd378471)                                                                    |
| James Sturtevant (@jsturtevant)    | [Windows Containers on Windows 10 without Docker (using Containerd)](https://www.jamessturtevant.com/posts/Windows-Containers-on-Windows-10-without-Docker-using-Containerd/) |
| kubernetes-sigs/sig-windows-tools  | [Install-Containerd.ps1](https://github.com/kubernetes-sigs/sig-windows-tools/blob/master/hostprocess/Install-Containerd.ps1)                                                 |
| Marat Radchenko (@slonopotamus)    | [Stevedore](https://github.com/slonopotamus/stevedore)                                                                                                                        |
| Markus Lippert (@lippertmarkus)    | [containerd-installer](https://github.com/lippertmarkus/containerd-installer)                                                                                                 |
| microsoft/Windows-Containers       | [install-containerd-runtime.ps1](https://github.com/microsoft/Windows-Containers/blob/Main/helpful_tools/Install-ContainerdRuntime/install-containerd-runtime.ps1)            |
| Mirantis                           | [Install MCR on Windows Servers](https://docs.mirantis.com/mcr/20.10/install/mcr-windows.html)                                                                                |

## Container tools installed with this module

- [Containerd](https://github.com/containerd/containerd)
- [BuildKit](https://github.com/moby/buildkit)
- [nerdctl](https://github.com/containerd/nerdctl)
- [Container networking plugins for Windows containers](https://github.com/microsoft/windows-container-networking)
- [Container Network Interface - networking for Linux containers](https://github.com/containernetworking/cni)
