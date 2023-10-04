---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Install-Nerdctl

## SYNOPSIS

Downloads and installs Nerdctl.

## SYNTAX

```
Install-Nerdctl [[-Version] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>] [<CommonParameters>]
```

## DESCRIPTION

Downloads Containerd files from [nerdctl releases](https://github.com/containerd/nerdctl/releases) and installs it the provided path. Once installation is complete, the downloaded files are deleted to save on disk space.

## EXAMPLES

### Example 1: Using defaults

Installs Nerdctl using default version nad path.

```powershell
PS C:\> Install-Nerdctl
```

### Example 2: Using custom values

Installs Nerdctl version 1.6.1 at 'C:\Test\Path\Nerdctl' and adds 'C:\Test\Path\Nerdctl' in the environment path.

```powershell
PS C:\> Install-Nerdctl -Version "1.6.1" -InstallPath 'C:\Test\Path\Nerdctl'
```

## PARAMETERS

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

### -InstallPath

Path to install Nerdctl. Path to install Nerdctl. Defaults to `$ENV:ProramFiles\Nerdctl`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $ENV:ProramFiles\Nerdctl`
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version

Nerdctl version to install. Defaults to latest version.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## RELATED LINKS

- [Get-NerdctlLatestVersion](Get-NerdctlLatestVersion.md)
- [Uninstall-Nerdctl](Uninstall-Nerdctl.md)
