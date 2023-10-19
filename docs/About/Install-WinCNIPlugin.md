---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Install-WinCNIPlugin

## SYNOPSIS

Downloads and installs Windows CNI plugin.

## SYNTAX

```
Install-WinCNIPlugin [[-WinCNIVersion] <String>] [[-WinCNIPath] <String>] [<CommonParameters>]
```

## DESCRIPTION

Downloads Windows CNI plugin from [windows-container-networking](https://github.com/microsoft/windows-container-networking/releases) and installs it in the specified location.

## EXAMPLES

### Example 1: Using defaults

Installs latest Windows CNI plugin at the default path.

```powershell
PS C:\> Install-WinCNIPlugin
```

### Example 2: Using custom values

Installs Windows CNI plugin version 0.2.0 in the default path.

```powershell
PS C:\> Install-WinCNIPlugin -WinCNIVersion "0.2.0"
```

## PARAMETERS

### -WinCNIPath

Location to install Windows CNI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Path where containerd is installed or `$Env:ProgramFiles\Containerd`
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIVersion

Windows CNI plugin version to use. Defaults to latest version.

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

- [Get-WinCNILatestVersion](Get-WinCNILatestVersion.md)
- [Initialize-NatNetwork](Initialize-NatNetwork.md)
