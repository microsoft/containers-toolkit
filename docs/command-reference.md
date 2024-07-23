# Command Reference

## Table of Contents

- [General](#general)
  - [Show-ContainerTools](#show-containertools)
  - [Install-ContainerTools](#install-containertools)
- [Containerd](#containerd)
  - [Get-ContainerdLatestVersion](#get-containerdlatestversion)
  - [Install-Containerd](#install-containerd)
  - [Register-ContainerdService](#register-containerdservice)
  - [Start-ContainerdService](#start-containerdservice)
  - [Stop-ContainerdService](#stop-containerdservice)
  - [Uninstall-Containerd](#uninstall-containerd)
- [BuildKit](#buildkit)
  - [Get-BuildkitLatestVersion](#get-buildkitlatestversion)
  - [Install-BuildKit](#install-buildkit)
  - [Register-BuildkitdService](#register-buildkitdservice)
  - [Start-BuildkitdService](#start-buildkitdservice)
  - [Stop-BuildkitdService](#stop-buildkitdservice)
  - [Uninstall-BuildKit](#uninstall-buildkit)
- [nerdctl](#nerdctl)
  - [Get-NerdctlLatestVersion](#get-nerdctllatestversion)
  - [Install-Nerdctl](#install-nerdctl)
  - [Uninstall-Nerdctl](#uninstall-nerdctl)
- [Container Networking](#container-networking)
  - [Get-WinCNILatestVersion](#get-wincnilatestversion)
  - [Install-WinCNIPlugin](#install-wincniplugin)
  - [Initialize-NatNetwork](#initialize-natnetwork)
  - [Uninstall-WinCNIPlugin](#uninstall-wincniplugin)

### General

#### Show-ContainerTools

List container tools (Containerd, BuildKit, nerdctl) and shows if the tool is installed, the installed version and the latest available version.

**Parameters**

None

**Output**

| Name | Type | Description |
| -------- | ------- | ------- |
| Tool | String | Name of the container tool. Either Containerd, BuildKit, or nerdctl. |
| Installed | Boolean | Specifies whether the tool is installed or not. |
| Version | String | Installed version. |
| LatestVersion | String | Latest available version |

#### Install-ContainerTools

Downloads container tool (Containerd, BuildKit, nerdctl) asynchronously and installs them at the specified location

**Parameters**
| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| ContainerdVersion | String | Containerd version to install | Latest version |
| BuildKitVersion | String | BuildKit version to install | Latest version |
| nerdctlVersion | String | nerdctl version to install | Latest version |
| InstallPath | String | Path to install container tools | `$Env:ProgramFiles` |
| DownloadPath | String | Path to download container tools  | `$HOME\Downloads` |
| Cleanup | Switch | Specifies whether to cleanup after installation is done  |  |
| Force | Switch | Force install the tools even if they already exists at the specified path |  |
| RegisterServices | Switch | Register and Start Containerd and Buildkitd services and set up NAT network |  |
| Confirm | Switch | Prompts for confirmation before running the cmdlet. For more information, see the following articles: [about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#confirmpreference) and [about_Functions_CmdletBindingAttribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-7.4#confirmimpact) |  |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

### Containerd

#### Get-ContainerdLatestVersion

Returns the latest Containerd version number.

**Parameters**

None

**Output**

String

#### Install-Containerd

Downloads Containerd files from [Containerd releases](https://github.com/containerd/containerd/releases) and installs them at the provided path. After the installation is complete, the downloaded files are deleted to save disk space.

Once Containerd is installed and added to the environment path, we can get the path where it is installed using:

```PowerShell
((Get-Command -Name containerd.exe).Source | Split-Path -Parent).TrimEnd("\bin")
```

**NOTE:** If Containerd already exists at the specified install path, it will be uninstalled and the specified version will be installed.

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| Version | String | Containerd version to install | Latest version |
| InstallPath | String | Path to install Containerd | `$Env:ProgramFiles\containerd` |
| DownloadPath | String | Path to download Containerd  | `$HOME\Downloads` |
| Setup | Switch | Register and start Containerd Service once Containerd installation is done  |  |
| Force | Switch | Installs Containerd even if the tool already exists at the specified path |  |
| Confirm | Switch | Prompts for confirmation before running the cmdlet. For more information, see the following articles: [about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#confirmpreference) and [about_Functions_CmdletBindingAttribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-7.4#confirmimpact) |  |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

#### Register-ContainerdService

Create a default Containerd configuration file called `config.toml` at the Containerd path and registers the Containerd service.

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| ContainerdPath | String | Path where Containerd is installed | The Containerd path in the environment path variable or `$Env:ProgramFiles\containerd` |
| Start | Switch | Start Containerd service after registration is complete | |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

#### Start-ContainerdService

Starts Containerd service

**Parameters**

None

**Output**

None

#### Stop-ContainerdService

Stops Containerd service

**Parameters**

None

**Output**

None

#### Uninstall-Containerd

Does the following:

1. Stops Containerd service
2. Unregisters Containerd service
3. Deletes Containerd directory
4. Removes Containerd from the environment path

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| Path | String | Path where Containerd is installed | The Containerd path in the environment path variable or `$Env:ProgramFiles\containerd` |
| Force | Switch | Bypass confirmation to uninstall Containerd |  |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

### BuildKit

#### Get-BuildkitLatestVersion

Returns the latest BuildKit version number.

**Parameters**

None

**Output**

String

#### Install-BuildKit

Downloads BuildKit files from [Containerd releases](https://github.com/moby/buildkit/releases) and installs them at the provided path. After the installation is complete, the downloaded files are deleted to save disk space.

Once BuildKit is installed and added to the environment path, we can get the path where it is installed using:

```PowerShell
((Get-Command -Name buildctl.exe).Source | Split-Path -Parent).TrimEnd("\bin")
```

**NOTE:** If BuildKit already exists at the specified install path, it will be uninstalled and the specified version will be installed.

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| Version | String | BuildKit version to install | Latest version |
|InstallPath | String | Path to install BuildKit | `$Env:ProgramFiles\BuildKit` |
|DownloadPath | String | Path to download BuildKit | $HOME\Downloads |
| Setup | Switch | Register and start buildkitd Service once Containerd installation is done  |  |
| Force | Switch | Installs Buildkit even if the tool already exists at the specified path |  |
| Confirm | Switch | Prompts for confirmation before running the cmdlet. For more information, see the following articles: [about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#confirmpreference) and [about_Functions_CmdletBindingAttribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-7.4#confirmimpact) |  |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

#### Register-BuildkitdService

Registers the buildkitd service with a prompt to either register with the Containerd CNI configurations (0-containerd-nat.conf) or not.

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| BuildkitPath | String | Path where BuildKit is installed | The BuildKit path in the environment path variable or `$Env:ProgramFiles\BuildKit` |
| WinCNIPath | String | Path to Windows CNI plugin | The Containerd path in the environment path variable or `$Env:ProgramFiles\Containerd` |
| Start | Switch | Start buildkitd service after registration is complete | |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

#### Start-BuildkitdService

Starts BuildKit service and waits for 30 seconds for the service to start. If the service does not start within this time, execution terminates with an error.

**Parameters**

None

**Output**

None

#### Stop-BuildkitdService

Stops BuildKit service
**Parameters**

None

**Output**

None

#### Uninstall-BuildKit

Does the following:

1. Stops buildkitd service
2. Unregisters buildkitd service
3. Deletes BuildKit directory
4. Removes BuildKit from the environment path

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| Path | String | Path where BuildKit is installed | The BuildKit path in the environment path variable or `$Env:ProgramFiles\BuildKit` |
| Force | Switch | Bypass confirmation to uninstall BuildKit |  |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

### nerdctl

#### Get-NerdctlLatestVersion

Returns the latest nerdctl version number.

**Parameters**

None

**Output**

String

#### Install-Nerdctl

Downloads Containerd files from [nerdctl releases](https://github.com/containerd/nerdctl/releases) and installs them at the provided path. After the installation is complete, the downloaded files are deleted to save disk space.

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| Version | String | nerdctl version to install | Latest version |
| InstallPath | String | Path to install nerdctl | $Env:ProgramFiles\nerdctl |
| DownloadPath | String | Path to download nerdctl  | $HOME\Downloads |
| Dependencies | String[] | Specify the nerdctl dependencies (All, Containerd, Buildkit, WinCNIPlugin) to install. |  |
| Force | Switch | Installs nerdctl even if the tool already exists at the specified path |  |
| Confirm | Switch | Prompts for confirmation before running the cmdlet. For more information, see the following articles: [about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#confirmpreference) and [about_Functions_CmdletBindingAttribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-7.4#confirmimpact) |  |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

#### Uninstall-Nerdctl

Deletes the nerdctl directory and removes it from the environment variables.

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| Path | String | Path where nerdctl is installed | The nerdctl path in the environment path variable or `$Env:ProgramFiles\BuildKit` |
| Force | Switch | Bypass confirmation to uninstall nerdctl |  |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

### Container Networking

#### Get-WinCNILatestVersion

Returns the latest Windows CNI version number.

**Parameters**

None

**Output**

String

#### Install-WinCNIPlugin

Downloads Windows CNI plugin from [windows-container-networking](https://github.com/microsoft/windows-container-networking/releases) and installs it in the specified location.

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| WinCNIVersion | String | Windows CNI version to install | Latest version |
| WinCNIPath | String | Location to install Windows CNI | Path where Containerd is installed or `$Env:ProgramFiles\Containerd`|
| Force | Switch | Installs Windows CNI plugins even if the tool already exists at the specified path |  |
| Confirm | Switch | Prompts for confirmation before running the cmdlet. For more information, see the following articles: [about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#confirmpreference) and [about_Functions_CmdletBindingAttribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-7.4#confirmimpact) |  |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

#### Initialize-NatNetwork

Initializes a NAT network.

**NOTE**: This function installs the [HNS module](https://www.powershellgallery.com/packages/HNS/0.2.4).

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| NetworkName | String | Name of the network. If a network with a similar name exists, the function terminates with an error message |  Default: `nat` |
| Gateway | String | Gateway IP address | Default gateway address |
| CIDR | Int | Size of the subnet mask | 16 |
| WinCNIVersion | String | Windows CNI version to use | Latest version |
| WinCNIPath | String | Absolute path to cni directory ~\cni. Not ~\cni\bin | Path where Containerd is installed or `$Env:ProgramFiles\Containerd\cni` |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None

#### Uninstall-WinCNIPlugin

Uninstalls Windows CNI plugins.

**Parameters**

| Name | Type | Description | Default |
| -------- | ------- | ------- | ------- |
| Path | String | Path where Windows CNI plugins is installed | `$Env:ProgramFiles\containerd\cni` |
| Force | Switch | Bypass confirmation to uninstall Windows CNI plugins |  |
| WhatIf | Switch | Shows what would happen if the cmdlet runs. The cmdlet isn't run. |  |

**Output**

None
