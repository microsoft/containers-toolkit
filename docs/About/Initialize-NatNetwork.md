---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Initialize-NatNetwork

## SYNOPSIS

Initializes a NAT network.

## SYNTAX

```
Initialize-NatNetwork [[-NetworkName] <String>] [[-Gateway] <String>] [[-CIDR] <Int32>] [-WhatIf]
 [[-WinCNIVersion] <String>] [[-WinCNIPath] <String>] [<CommonParameters>]
```

## DESCRIPTION

Initializes a NAT network.

## EXAMPLES

### Example 1: Using defaults

Initializes a NAT network using default values.

```powershell
PS C:\> Initialize-NatNetwork
```

### Example 2: Using defaults

Initializes a NAT network using default values.

```powershell
PS C:\> Initialize-NatNetwork -NetworkName 'natNW' -Gateway '192.168.0.5' -CIDR 32
```

## PARAMETERS

### -CIDR

Size of the subnet mask. Defaults to 16

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 16
Accept pipeline input: False
Accept wildcard characters: False
```

### -Gateway

Gateway IP address. Defaults to default gateway address.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Default gateway address
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetworkName

Name of the new network. Defaults to 'nat'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: 'nat'
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIPath

Absolute path to cni folder.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Path where containerd is installed or $Env:ProgramFiles\Containerd\cni
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIVersion

Windows CNI plugin version to use.
Defaults to latest version.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Latest version
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

## NOTES

The version provided needs to match the installed version. To avoid any issues, it is safer to install the latest version.

If Windows CNI plugins are not installed at the default or provided path, the user is prompted to install the missing plugins.

```Output
Windows CNI plugins have not been installed.
Do you want to install the Windows CNI plugins?
[Y] Yes  [N] No  [?] Help (default is "N"):
```

- If a user enters `Y`, the user to consents to the download and installation of the missing plugins.
- If a user enters `N` (default), execution terminates with an error.

## RELATED LINKS

- [Get-WinCNILatestVersion](Get-WinCNILatestVersion.md)
- [Install-WinCNIPlugin](Install-WinCNIPlugin.md)
- [Uninstall-WinCNIPlugin](Uninstall-WinCNIPlugin.md)
