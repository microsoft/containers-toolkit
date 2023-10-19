---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Install-ContainerTools

## SYNOPSIS

Downloads and installs container tool (Containerd, BuildKit, and nerdctl).

## SYNTAX

```
Install-ContainerTools [[-ContainerDVersion] <String>] [[-BuildKitVersion] <String>]
 [[-NerdCTLVersion] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>] [-CleanUp]
 [<CommonParameters>]
```

## DESCRIPTION

Downloads container tool (Containerd, BuildKit, and nerdctl) asynchronously and installs them at the specified location.

## EXAMPLES

### Example 1: Using defaults

Install the latest versions of Containerd, BuildKit, and nerdctl at the default path

```powershell
PS C:\> Install-ContainerTools
```

### Example 2: Download Containerd version 1.6.8 and default nerdctl and BuildKit versions

Download Containerd version 1.6.8 and default nerdctl and BuildKit versions

```powershell
PS C:\> Install-ContainerTools -ContainerDVersion 1.6.8
```

### Example 3: Cleanup after installation is complete

Deletes downloaded files after installation is complete to save on disk space.

```powershell
PS C:\> Install-ContainerTools -Cleanup
```

## PARAMETERS

### -BuildKitVersion

BuildKit version to install

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Latest version
Accept pipeline input: False
Accept wildcard characters: False
```

### -CleanUp

Cleanup after installation is done

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

### -ContainerDVersion

Containerd version to install

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

### -DownloadPath

Path to download files. Defaults to user's Downloads folder, `$HOME\Downloads`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: $HOME\Downloads
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallPath

Path to Install files. Defaults to Program Files, `$Env:ProgramFiles`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: $Env:ProgramFiles
Accept pipeline input: False
Accept wildcard characters: False
```

### -NerdCTLVersion

nerdctl version to install

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Latest version
Accept pipeline input: False
Accept wildcard characters: False
```

## RELATED LINKS

- [Install-Containerd](Install-Containerd.md)
- [Install-BuildKit](Install-BuildKit.md)
- [Install-Nerdctl](Install-Nerdctl.md)
