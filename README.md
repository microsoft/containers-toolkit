# Table of contents

1. [Introduction](#introduction)
2. [Usage](#usage)
    - [Importing the module](#importing-the-module)
    - [Command reference](#command-reference)
3. [TODO](#todo)
4. [Contribution](#contribution)
5. [References](#references)

## Introduction

ContainerToolsForWindows is a Windows PowerShell module for downloading, installing, and setting up default configs for Containerd, Buildkit, Windows CNI plugin, and Nerdctl.

## Usage

### Importing the module

#### Option 1

You can manually import this module using:

```PowerShell
Import-Module -Name <absolute-path>\ContainerToolsForWindows.psd1 -Force
```

#### Option 2

---
**Option 2a:**

1. Aternatively, you can add it to the Windows PowerShell module path. To get the possible module paths, use:

    ```PowerShell
    $env:PSModulePath
    ```

2. Move the folder to any of the paths from the above PS command

**Option 2b:**

1. Add the location of the module directory to `$env:PSModulePath`

    ```PowerShell
    $env:PSModulePath += "$env:PSModulePath;<path-to-module-directory>"
    ```

2. Reload the terminal or open a new terminal

---

3. Import the module

    ```PowerShell
    Import-Module -Name ContainerToolsForWindows -Force
    ```

3. Get the module details

    ```PowerShell
    Get-Module -Name ContainerToolsForWindows
    ```

### Command reference

1. [Command reference](./docs/command-reference.md)
2. Detailed command reference can be found in the [About](./docs/About/) section

## TODO

- [ ] Rename this module: The current name for this module might cause confusion with repo named windows-containers-tools
- [x] Update README.md (Documentation)
- [x] Update ContainerToolsForWindows/ContainerToolsForWindows.Format.ps1xml (Documentation)
- [x] Update ContainerToolsForWindows/en-US/about_ContainerToolsForWindows.help.txt (Documentation)
- [ ] Publish module to PSGallery
- [ ] Dev install: (Hacks) Add functions in Containerd and Buildkit to build from source files. (Is this really necessary? May be an overkill)
- [x] Use latest version in download
- [ ] Add Pester test
- [ ] Pipeline configuration
- [ ] Rootless installation

## Contribution

## Similar Projects

- [Install-ContainerdRuntime
](https://github.com/microsoft/Windows-Containers/blob/Main/helpful_tools/Install-ContainerdRuntime/install-containerd-runtime.ps1)
- [containerd-installer](https://github.com/lippertmarkus/containerd-installer)
- [Install MCR on Windows Servers](https://docs.mirantis.com/mcr/20.10/install/mcr-windows.html)
- [Stevedore](https://github.com/slonopotamus/stevedore)

## References

- [Containerd](https://github.com/containerd/containerd)
- [Buildkit](https://github.com/moby/buildkit)
- [Nerdctl](https://github.com/containerd/nerdctl)
- [Container networking plugins for Windows containers](https://github.com/microsoft/windows-container-networking)
