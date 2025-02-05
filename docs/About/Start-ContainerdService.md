---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Start-ContainerdService

## SYNOPSIS

Starts Containerd service.

## SYNTAX

```
Start-ContainerdService [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Starts Containerd service and waits for 30 seconds for the service to start. If the service does not start within the this time, execution terminates with an error.

## EXAMPLES

### Example 1

Start Containerd Service.

```powershell
PS C:\> Start-ContainerdService
```

## PARAMETERS

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

- [Start-Service](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-service?view=powershell-7.3)
- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Install-Containerd](Install-Containerd.md)
- [Register-ContainerdService](Register-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
