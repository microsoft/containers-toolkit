---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---


# Uninstall-Buildkit

## SYNOPSIS

Uninstalls BuildKit.

## SYNTAX

```
Uninstall-Buildkit [[-Path] <String>] [-Purge] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

To uninstall BuildKit, this command stops buildkitd service and unregisters buildkitd service.
The BuildKit directory is then deleted and BuildKit is removed from the environment path.

## EXAMPLES

### Example 1

Uninstall BuildKit from the default path.

```powershell
PS C:\> Uninstall-Buildkit
```

## PARAMETERS

### -Force

Bypass confirmation to uninstall BuildKit

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

BuildKit path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: The Buildkit path in the environment path variable or `$Env:ProgramFiles\Buildkit`
Accept pipeline input: False
Accept wildcard characters: False
```

### -Purge

Delete all Buildkit program files and program data.

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

- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Install-Buildkit](Install-Buildkit.md)
- [Register-BuildkitdService](Register-BuildkitdService.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
