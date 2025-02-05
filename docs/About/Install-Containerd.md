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
Install-Containerd [[-Version] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>]
 [-RegisterService] [-OSArchitecture <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Downloads Containerd files from [Containerd releases](https://github.com/containerd/containerd/releases) and installs it the provided path. After installation is complete, the downloaded files are deleted to save on disk space.
We can get the path where it is installed using:

```PowerShell
((Get-Command -Name containerd.exe).Source | Split-Path -Parent).TrimEnd("\bin")
```

**NOTE:** If `-Force` is specified and Containerd is already present at the specified install path, it will be uninstalled and replaced with the specified version. Otherwise, the installation will be skipped.

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

## PARAMETERS

### -DownloadPath

Path to download files. Defaults to `$HOME\Downloads`

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
Default value: False
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

### -OSArchitecture

OS architecture to download files for. Default is `$env:PROCESSOR_ARCHITECTURE`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $env:PROCESSOR_ARCHITECTURE
Accept pipeline input: False
Accept wildcard characters: False
```

### -RegisterService

Register and start the Containerd Service.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: Setup

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version

ContainerD version to use. Defaults to latest version

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: latest
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## RELATED LINKS

- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Register-ContainerdService](Register-ContainerdService.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
