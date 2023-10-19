---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Install-Containerd

## SYNOPSIS

Downloads and installs Containerd.

## SYNTAX

```
Install-Containerd [[-Version] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>]
 [<CommonParameters>]
```

## DESCRIPTION

Downloads Containerd files from [containerd releases](https://github.com/containerd/containerd/releases) and installs it the provided path. Once installation is complete, the downloaded files are deleted to save on disk space.

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

Path to install containerd. Defaults to `$ENV:ProramFiles\containerd`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $ENV:ProramFiles\containerd
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version

ContainerD version to install. Defaults to latest version

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

## INPUTS

### None

## OUTPUTS

## NOTES

## RELATED LINKS

- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Initialize-ContainerdService](Initialize-ContainerdService.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
