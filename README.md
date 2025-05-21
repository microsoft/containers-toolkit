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
1. [Prerequisites](#prerequisites)
1. [Installation and Setup](#installation-and-setup)
1. [Usage](#usage)
1. [Important Notes](#important-notes)
1. [FAQs](#faqs)
1. [Contribution](#contribution)

## Introduction

Containers-Toolkit is a Windows PowerShell module for downloading, installing, and configuring Containerd, Buildkit, nerdctl, and Windows CNI plugins for container networks. It also allows you to get a list of the container tools and their installation statuses.

Configurations done with these functions are default configurations that allow you to get started with interacting with the tools. Further configurations may be necessary.
You can find documentation for these functions here: [Containers-Toolkit Documentation](https://github.com/microsoft/containers-toolkit/tree/main/docs/command-reference.md)

## Prerequisites

1. PowerShell: Minimum Version 7

1. `HNS` module

    To install the HNS module, follow the [instructions here](./docs/FAQs.md#2-new-hnsnetwork-command-does-not-exist)

    **Reference:**
    - [HostNetworkingService](https://docs.microsoft.com/en-us/powershell/module/hostnetworkingservice/?view=windowsserver2022-ps)
    - [Container Network Management with Host Network Service (HNS)](https://learn.microsoft.com/en-us/virtualization/windowscontainers/container-networking/architecture#container-network-management-with-host-network-service)

## Installation and Setup

### Install Containers-Toolkit module from PowerShell Gallery

> COMING SOON: We are currently working on publishing this module to PS Gallery to make it easier to import the module

### Download signed source files

> Coming soon

### Downloading the source code from Containers-Toolkit repository

To use the module, fork/clone the repository to your local machine and [setup your development environment](./CONTRIBUTING.md#setup-development-environment)

## Usage

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

### Logging

The module uses a static logger designed for use across module files within the **Containers Toolkit**. It supports configurable log levels, console output, optional log file writing, and integration with the **Windows Event Log**.
The logger supports the following log levels:

- `DEBUG`
- `INFO`
- `WARNING`
- `ERROR`
- `FATAL`

For more details on the logger, please refer to the [Logger documentation](./docs/LOGGER.md).

#### Logging Environment Variables

See [Logger documentation](./docs/LOGGER.md#environment-variables) for more details on the environment variables used to control logging.

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

1. Requires PowerShell modules [HNS](https://raw.githubusercontent.com/microsoft/SDN/master/Kubernetes/windows/hns.v2.psm1)

## FAQs

Please visit the [FAQs.md](./docs/FAQs.md) to see the how to resolve common issues.

## Contribution

Please look into the [Contribution Guide](./CONTRIBUTING.md) to know how to develop and contribute.

## Legal and Licensing

PowerShell is licensed under the [MIT license](./LICENSE).

## Code of Conduct

Please see our [Code of Conduct](./CODE_OF_CONDUCT.md) before participating in this project.

## Security Policy

For any security issues, please see our [Security Policy](./SECURITY.md).

## Attributions

This project builds on the work of others to create a PowerShell module.

Credits (in alphabetic order):

<!-- textlint-disable -->

| Author/Repository                  | Link                                                                                                                                                                          |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Anthony Nandaa (@profnandaa)       | [cni-setup-legacy.ps1](https://gist.github.com/profnandaa/33d65d85964181a42539bfd0b4f9561a)                                                                                   |
| Gabriel Samfira (@gabriel-samfira) | [setup_buildkitd_on_windows.ps1](https://gist.github.com/gabriel-samfira/6e56238ad11c24f490ac109bdd378471)                                                                    |
| James Sturtevant (@jsturtevant)    | [Windows Containers on Windows 10 without Docker (using Containerd)](https://www.jamessturtevant.com/posts/Windows-Containers-on-Windows-10-without-Docker-using-Containerd/) |
| kubernetes-sigs/sig-windows-tools  | [Install-Containerd.ps1](https://github.com/kubernetes-sigs/sig-windows-tools/blob/master/hostprocess/Install-Containerd.ps1)                                                 |
| Marat Radchenko (@slonopotamus)    | [Stevedore](https://github.com/slonopotamus/stevedore)                                                                                                                        |
| Markus Lippert (@lippertmarkus)    | [containerd-installer](https://github.com/lippertmarkus/containerd-installer)                                                                                                 |
| microsoft/Windows-Containers       | [install-containerd-runtime.ps1](https://github.com/microsoft/Windows-Containers/blob/Main/helpful_tools/Install-ContainerdRuntime/install-containerd-runtime.ps1)            |
| Mirantis                           | [Install MCR on Windows Servers](https://docs.mirantis.com/mcr/20.10/install/mcr-windows.html)                                                                                |

<!-- textlint-enable -->

## Container tools installed with this module

- [Containerd](https://github.com/containerd/containerd)
- [BuildKit](https://github.com/moby/buildkit)
- [nerdctl](https://github.com/containerd/nerdctl)
- [Container networking plugins for Windows containers](https://github.com/microsoft/windows-container-networking)
- [Container Network Interface - networking for Linux containers](https://github.com/containernetworking/cni)
