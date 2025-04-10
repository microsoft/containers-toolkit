---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Register-ContainerdService

## SYNOPSIS

Create a default Containerd configuration file called `config.toml` at the Containerd path and registers the Containerd service.

## SYNTAX

```
Register-ContainerdService [[-ContainerdPath] <String>] [-Start] [<CommonParameters>]
```

## DESCRIPTION

Create a default Containerd configuration file called `config.toml` at the Containerd path and registers the Containerd service.

## EXAMPLES

### Example 1: Using default Containerd path

Creates the config.toml file at the default Containerd path and registers the Containerd service.

```powershell
PS C:\> Register-ContainerdService
```

### Example 2: Using custom path

Creates the config.toml file at the provided Containerd path and registers the Containerd service. If Containerd does not exist at the provided path, execution fails with an error.

```powershell
PS C:\> Register-ContainerdService -ContainerdPath 'C:\Test\Path\containerd'
```

## PARAMETERS

### -ContainerdPath

Path where Containerd is installed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: $Env:ProgramFiles\containerd
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Bypass confirmation to register containerd service

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

### -Start

Specify to start Containerd service after registration is complete

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

- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Install-Containerd](Install-Containerd.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
