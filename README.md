# Table of contents

1. [Introduction](#introduction)
2. [Usage](#usage)
    - [Importing the module](#importing-the-module)
    - [Command reference](#command-reference)
3. [TODO](#todo)
4. [Contribution](#contribution)
5. [References](#references)

## Introduction

ContainerToolsForWindows is a Windows PowerShell module for downloading, installing, and setting up default configs for Containerd, BuildKit, Windows CNI plugin, and nerdctl.

## Usage

### Importing the module

#### Option 1
Manually import this module using:
```PowerShell
Import-Module -Name <absolute-path>\ContainerToolsForWindows.psd1 -Force
```

#### Option 2
Clone containers-toolkit into one of the folder locations in the `$env:PSModulePath` environment variable.

To get a possible module path:
```PowerShell
$env:PSModulePath
```

```PowerShell
cd <module path>
git clone https://github.com/microsoft/containers-toolkit.git
```
```PowerShell
Import-Module -Name ContainerToolsForWindows -Force
```

#### Option 3
Clone containers-toolkit to a folder location of choice and add the new module location to the Windows PowerShell module path

```PowerShell
cd <module path>
git clone https://github.com/microsoft/containers-toolkit.git
```
```PowerShell
$env:PSModulePath += "$env:PSModulePath;<path-to-module-directory>"
```
```PowerShell
Import-Module -Name ContainerToolsForWindows -Force
```

###Get the module details

```PowerShell
Get-Help ContainerToolsForWindows
```

```PowerShell
Get-Module -Name ContainerToolsForWindows
```

### Command reference

1. List of all available commands can be found in the [Command reference](./docs/command-reference.md) section
1. Detailed command reference for each cmdlet can be found in the [About](./docs/About/) section

#### List of available commands

```PowerShell
Get-Command -Module ContainerToolsForWindows
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

### Important Notes

To use these tools (Containerd, BuildKit, and nerdCtl), ensure that Containers and HyperV Windows features are enabled.

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

## TODO

- [ ] Rename this module to containerstoolkit: The current name for this module might cause confusion with repository named windows-containers-tools
- [ ] Pipeline configuration
- [ ] Publish module to PSGallery
- [ ] Fix Code analysis warnings
- [ ] Rootless installation
- [ ] Dev install: (Hacks) Add functions in Containerd and BuildKit to build from source files. (Is this really necessary? May be an overkill)
- [x] Update README.md (Documentation)
- [x] Update ContainerToolsForWindows/ContainerToolsForWindows.Format.ps1xml (Documentation)
- [x] Update ContainerToolsForWindows/en-US/about_ContainerToolsForWindows.help.txt (Documentation)
- [x] Use latest version in download
- [x] Add Pester test
- [x] Replace GitHub username in URL: <https://github.com/...>

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

## Container tools repositories

- [Containerd](https://github.com/containerd/containerd)
- [BuildKit](https://github.com/moby/buildkit)
- [Nerdctl](https://github.com/containerd/nerdctl)
- [Container networking plugins for Windows containers](https://github.com/microsoft/windows-container-networking)
