---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Install-ContainerTools

## SYNOPSIS

Downloads and installs container tool (Containerd, Buildkit, and Nerdctl).

## SYNTAX

```
Install-ContainerTools [[-ContainerDVersion] <String>] [[-BuildKitVersion] <String>]
 [[-NerdCTLVersion] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>] [-CleanUp]
 [<CommonParameters>]
```

## DESCRIPTION

Downloads container tool (Containerd, Buildkit, and Nerdctl) asynchronously and installs them at the specified location.

## EXAMPLES

### Example 1: Using defaults

Install the latest versions of Containerd, Buildkit, and Nerdctl at the default path

```powershell
PS C:\> Install-ContainerTools
```

### Example 2: Download Containerd version 1.6.8 and default Nerdctl and Buildkit versions

Download Containerd version 1.6.8 and default Nerdctl and Buildkit versions

```powershell
PS C:\> Install-ContainerTools -ContainerDVersion 1.6.8
```

### Example 3: Cleanup after installation is complete

Deletes donwloaded files after installation is complete to save on disk space.

```powershell
PS C:\> Install-ContainerTools -Cleanup
```

## PARAMETERS

### -BuildKitVersion

Buildkit version to install

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

ContainerD version to install

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

Nerdctl version to install

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## RELATED LINKS

- [Install-Containerd](Install-Containerd.md)
- [Install-Buildkit](Install-Buildkit.md)
- [Install-Nerdctl](Install-Nerdctl.md)
