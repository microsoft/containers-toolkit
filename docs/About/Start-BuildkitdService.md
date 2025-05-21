---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Start-BuildkitdService

## SYNOPSIS

Starts buildkitd service.

## SYNTAX

```
Start-BuildkitdService [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Starts buildkitd service and waits for 30 seconds for the service to start. If the service does not start within the this time, execution terminates with an error.

## EXAMPLES

### Example 1

Start buildkitd Service.

```powershell
PS C:\> Start-BuildkitdService
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
- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Install-Buildkit](Install-Buildkit.md)
- [Register-BuildkitdService](Register-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-Buildkit](Uninstall-Buildkit.md)
