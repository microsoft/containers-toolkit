---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Install-Containerd

## SYNOPSIS

Downloads and installs Containerd.

## SYNTAX

```
Install-Containerd [[-Version] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>] [-Setup] [-Force]
 [-Confirm] [-WhatIf] [<CommonParameters>]
```

## DESCRIPTION

Downloads Containerd files from [Containerd releases](https://github.com/containerd/containerd/releases) and installs it the provided path. Once installation is complete, the downloaded files are deleted to save on disk space.

Once Containerd is installed and added to the environment path, we can get the path where it is installed using:

```PowerShell
((Get-Command -Name containerd.exe).Source | Split-Path -Parent).TrimEnd("\bin")
```

**NOTE:** If Containerd already exists at the specified install path, it will be uninstalled and the specified version will be installed.

## EXAMPLES

### Example 1: Using defaults

Installs Containerd using defaults

```powershell
PS C:\> Install-Containerd
```

### Example 2: Using custom values

Installs Containerd version 1.7.7 at 'C:\Test\Path\containerd' and adds 'C:\Test\Path\containerd' in the environment path.

```powershell
PS C:\> Install-Containerd -Version "1.7.7" -InstallPath 'C:\Test\Path\Containerd'
```

## PARAMETERS

### -Confirm

Prompts for confirmation before running the cmdlet. For more information, see the following articles:

- [about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#confirmpreference)
- [about_Functions_CmdletBindingAttribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-7.4#confirmimpact)

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DownloadPath

Path to download files. Defaults to user's Downloads folder

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $HOME\Downloads
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Installs Containerd even if the tool already exists at the specified path.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallPath

Path to install Containerd. Defaults to Defaults to `$ENV:ProramFiles\containerd`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value:  $ENV:ProramFiles\containerd
Accept pipeline input: False
Accept wildcard characters: False
```

### -Setup

Register and start Containerd Service once Containerd installation is done

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version

Containerd version to install. Defaults to latest version

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: Latest version
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet isn't run.

```yaml
Type: SwitchParameter
Parameter Sets: Setup
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## RELATED LINKS

- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Register-ContainerdService](Register-ContainerdService.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
