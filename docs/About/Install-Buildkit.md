---
external help file: containers-toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Install-Buildkit

## SYNOPSIS

Downloads and installs BuildKit.

## SYNTAX

### Install (Default)

```
Install-Buildkit [-Version <String>] [-InstallPath <String>] [-DownloadPath <String>] [-OSArchitecture <String>]
 [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Setup

```
Install-Buildkit [-Version <String>] [-InstallPath <String>] [-DownloadPath <String>] [-RegisterService]
 [-WinCNIPath <String>] [-OSArchitecture <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Downloads BuildKit files from [Containerd releases](https://github.com/moby/buildkit/releases) and installs it the provided path. After installation is complete, the downloaded files are deleted to save on disk space.
We can get the path where Buildkit is installed using:

```PowerShell
((Get-Command -Name "buildkitd.exe").Source | Split-Path -Parent).TrimEnd("\bin")
```

**NOTE:** If `-Force` is specified and BuildKit is already present at the specified install path, it will be uninstalled and replaced with the specified version. Otherwise, the installation will be skipped.

## EXAMPLES

### Example 1: Using defaults

Installs BuildKit using default version and path.

```powershell
PS C:\> Install-BuildKit
```

### Example 2: Using custom values

Installs BuildKit version 0.12.2 at 'C:\Test\Path\buildkit' and adds 'C:\Test\Path\buildkit' in the environment path.

```powershell
PS C:\> Install-BuildKit -Version "0.12.2" -InstallPath 'C:\Test\Path\buildkit'
```

## PARAMETERS

### -DownloadPath

Path to download files. Defaults to `$HOME\Downloads`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $HOME\Downloads
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Installs Buildkit even if the tool already exists at the specified path.

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

Path to install BuildKit. Defaults to `$ENV:ProgramFiles\BuildKit`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $Env:ProgramFiles\Buildkit
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

### -RegisterService

Register and start the buildkitd Service.

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

Buildkit version to use. Defaults to latest version.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: latest
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIPath

Path where Windows CNI plugins are installed. Defaults to $ENV:ProgramFiles\Containerd\cni

```yaml
Type: String
Parameter Sets: Setup
Aliases:

Required: False
Position: Named
Default value: $ENV:ProgramFiles\Containerd\cni
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
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## RELATED LINKS

- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Register-BuildkitdService](Register-BuildkitdService.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-BuildKit](Uninstall-BuildKit.md)
