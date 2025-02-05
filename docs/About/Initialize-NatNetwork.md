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
Initialize-NatNetwork [[-NetworkName] <String>] [[-Gateway] <String>] [[-CIDR] <Int32>]
 [[-WinCNIVersion] <String>] [[-WinCNIPath] <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
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

### -Force

Bypass confirmation to install any missing dependencies (Windows CNI plugins and HNS module)

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

### -Gateway

Gateway IP address. Defaults to default gateway address.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetworkName

Name of the new network. Defaults to 'nat'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: nat
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIPath

Absolute path to cni folder, e.g. ~\cni (not ~\cni\bin).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: $env:ProgramFiles\containerd\cni
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIVersion

Windows CNI plugins version to use. Defaults to latest version.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: latest
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

## NOTES

The specified version must match the installed version. To avoid compatibility issues, it is recommended to install the latest version.  

If the CNI plugins are not found at the default or specified path, the user will be prompted to install them —unless `-Confirm`
is explicitly set to `$false`, in which case the plugins will be installed automatically without prompting.  

If the user declines the installation, the NAT network setup operation will be terminated with a warning.

## RELATED LINKS

- [Get-WinCNILatestVersion](Get-WinCNILatestVersion.md)
- [Install-WinCNIPlugin](Install-WinCNIPlugin.md)
- [Uninstall-WinCNIPlugin](Uninstall-WinCNIPlugin.md)
