---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Uninstall-WinCNIPlugin

## SYNOPSIS

Uninstall Windows CNI plugins.

## SYNTAX

```
Uninstall-WinCNIPlugin [[-Path] <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Uninstall Windows CNI plugins from the default or provided path. The default path is `$ENV:ProgramFiles\Containerd\cni`.

## EXAMPLES

### Example 1

Uninstalls WinCNIPlugins from the default path, `$ENV:ProgramFiles\Containerd\cni`

```powershell
PS C:\> Uninstall-WinCNIPlugin 
```

## PARAMETERS

### -Force

Bypass confirmation to uninstall Windows CNI plugins

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

### -Path

Windows CNI plugin path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
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

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

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

- [Get-WinCNILatestVersion](Get-WinCNILatestVersion.md)
- [Install-WinCNIPlugin](Install-WinCNIPlugin.md)
- [Initialize-NatNetwork](Initialize-NatNetwork.md)
