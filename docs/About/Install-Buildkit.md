---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Install-Buildkit

## SYNOPSIS

Downloads and installs Buildkit.

## SYNTAX

```
Install-Buildkit [[-Version] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>]
 [<CommonParameters>]
```

## DESCRIPTION

Downloads Buildkit files from [containerd releases](https://github.com/moby/buildkit/releases) and installs it the provided path. Once installation is complete, the downloaded files are deleted to save on disk space.

Once Buildkit is installed and added to the environment path, we can get the path where it is installed using:

```PowerShell
((Get-Command -Name "build*.exe" | Where-Object {$_.Source -like "*buildkit*"} | Select-Object -Unique).Source | Split-Path -Parent).TrimEnd("\bin")
```

**NOTE:** If Buildkit already exists at the specified install path, it will be uninstalled and the specified version will be installed.

## EXAMPLES

### Example 1: Using defaults

Installs Buildkit using default version nad path.

```powershell
PS C:\> Install-Buildkit
```

### Example 2: Using custom values

Installs Buildkit version 0.12.2 at 'C:\Test\Path\buildkit' and adds 'C:\Test\Path\buildkit' in the environment path.

```powershell
PS C:\> Install-Buildkit -Version "0.12.2" -InstallPath 'C:\Test\Path\buildkit'
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

Path to install buildkit. Defaults to `$ENV:ProramFiles\buildkit`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $Env:ProgramFiles\Buildkit
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version

Buildkit version to install. Defaults to latest version.

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

- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Initialize-BuildkitdService](Initialize-BuildkitdService.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-Buildkit](Uninstall-Buildkit.md)
