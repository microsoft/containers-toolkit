---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Uninstall-Nerdctl

## SYNOPSIS

Uninstalls nerdctl.

## SYNTAX

```
Uninstall-Nerdctl [[-Path] <String>] [-Purge] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

To uninstall nerdctl, the nerdctl directory is deleted and nerdctl is removed from the environment path.

## EXAMPLES

### Example 1

Uninstall nerdctl from the default path.

```powershell
PS C:\> Uninstall-Nerdctl
```

## PARAMETERS

### -Force

Bypass confirmation to uninstall nerdctl

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

nerdctl path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: $Env:ProgramFiles\nerdctl
Accept pipeline input: False
Accept wildcard characters: False
```

### -Purge

Delete all nerdctl program files and program data.

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

- [Get-NerdctlLatestVersion](Get-NerdctlLatestVersion.md)
- [Install-Nerdctl](Install-Nerdctl.md)
