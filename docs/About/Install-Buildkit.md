---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Install-Buildkit

## SYNOPSIS

Downloads and installs BuildKit.

## SYNTAX

### Install (Default)

```
Install-Buildkit [-Version <String>] [-InstallPath <String>] [-DownloadPath <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Setup

```
Install-Buildkit [-Version <String>] [-InstallPath <String>] [-DownloadPath <String>] [-Setup]
 [-WinCNIPath <String>] [-Force] [-Confirm] [-WhatIf] [<CommonParameters>]
```

## DESCRIPTION

Downloads BuildKit files from [Containerd releases](https://github.com/moby/buildkit/releases) and installs it the provided path. Once installation is complete, the downloaded files are deleted to save on disk space.

Once BuildKit is installed and added to the environment path, we can get the path where it is installed using:

```PowerShell
((Get-Command -Name "build*.exe" | Where-Object {$_.Source -like "*buildkit*"} | Select-Object -Unique).Source | Split-Path -Parent).TrimEnd("\bin")
```

**NOTE:** If BuildKit already exists at the specified install path, it will be uninstalled and the specified version will be installed.

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

### -DownloadPath

Path to download files. Defaults to user's Downloads folder

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

Path to install BuildKit. Defaults to `$ENV:ProramFiles\BuildKit`

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

### -Setup

Register and start buildkitd Service once BuildKit installation is done.

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

### -Version

Buildkit version to install. Defaults to latest version

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Latest version
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

- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Register-BuildkitdService](Register-BuildkitdService.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-BuildKit](Uninstall-BuildKit.md)
