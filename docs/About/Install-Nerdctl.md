---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Install-Nerdctl

## SYNOPSIS

Downloads and installs nerdctl.

## SYNTAX

```
Install-Nerdctl [[-Version] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>]
 [[-Dependencies] <String[]>] [-OSArchitecture <string>] [-Force] [-Confirm] [-WhatIf] [<CommonParameters>]
```

## DESCRIPTION

Downloads Containerd files from [nerdctl releases](https://github.com/containerd/nerdctl/releases) and installs it the provided path. Once installation is complete, the downloaded files are deleted to save on disk space.

## EXAMPLES

### Example 1: Using defaults

Installs nerdctl using default version and path.

```powershell
PS C:\> Install-Nerdctl
```

### Example 2: Using custom values

Installs nerdctl version 1.6.1 at 'C:\Test\Path\nerdctl' and adds 'C:\Test\Path\nerdctl' in the environment path.

```powershell
PS C:\> Install-Nerdctl -Version "1.6.1" -InstallPath 'C:\Test\Path\nerdctl'
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

### -Dependencies

Specify the nerdctl dependencies (All, Containerd, Buildkit, WinCNIPlugin) to install. Input type: array

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
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

Installs nerdctl (and its dependecies if specified) even if the tool already exists at the specified path.

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

### -InstallPath

Path to install nerdctl. Defaults to `$ENV:ProramFiles\nerdctl`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $ENV:ProramFiles\nerdctl`
Accept pipeline input: False
Accept wildcard characters: False
```

### -OSArchitecture

OS architecture to download files for.
Default is `$env:PROCESSOR_ARCHITECTURE`

```yaml
Type: String
Parameter Sets: Setup
Aliases:

Required: False
Position: Named
Default value:  $env:PROCESSOR_ARCHITECTURE
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version

nerdctl version to install. Defaults to latest version.

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

- [Get-NerdctlLatestVersion](Get-NerdctlLatestVersion.md)
- [Uninstall-Nerdctl](Uninstall-Nerdctl.md)
