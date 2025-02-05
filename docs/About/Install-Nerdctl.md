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
 [[-Dependencies] <String[]>] [-OSArchitecture <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Downloads Containerd files from [nerdctl releases](https://github.com/containerd/nerdctl/releases) and installs it the provided path. After installation is complete, the downloaded files are deleted to save on disk space.

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

### -Dependencies

Specify the nerdctl dependencies (All, Containerd, Buildkit, WinCNIPlugin) to install.

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

Path to download files. Defaults to user's Downloads folder, `$HOME\Downloads`

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

Force nerdctl (and its dependecies if specified) uninstallation (if it exists) without any confirmation prompts

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

Path to install nerdctl.
Defaults to `$ENV:ProgramFiles\nerdctl`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $ENV:ProgramFiles\nerdctl`
Accept pipeline input: False
Accept wildcard characters: False
```

### -OSArchitecture

OS architecture to download files for.
Default is `$env:PROCESSOR_ARCHITECTURE`

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

### -Version

nerdctl version to install.
Defaults to latest version.

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

Prompts for confirmation before running the cmdlet.

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

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## RELATED LINKS

- [Get-NerdctlLatestVersion](Get-NerdctlLatestVersion.md)
- [Uninstall-Nerdctl](Uninstall-Nerdctl.md)
