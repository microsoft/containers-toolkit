---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Install-Nerdctl

## SYNOPSIS

Downloads and installs nerdctl.

## SYNTAX

```
Install-Nerdctl [[-Version] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>] [<CommonParameters>]
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

Path to install nerdctl. Defaults to `$ENV:ProramFiles\Nerdctl`

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

## RELATED LINKS

- [Get-NerdctlLatestVersion](Get-NerdctlLatestVersion.md)
- [Uninstall-Nerdctl](Uninstall-Nerdctl.md)
