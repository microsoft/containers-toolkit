---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Register-BuildkitdService

## SYNOPSIS

Registers the buildkitd service with a prompt to either register with the Containerd CNI configurations (0-containerd-nat.conf) or not.

## SYNTAX

```
Register-BuildkitdService [[-WinCNIPath] <String>] [[-BuildKitPath] <String>] [-Start] [-WhatIf]
 [<CommonParameters>]
```

## DESCRIPTION

Registers the buildkitd service with a prompt to either register with the Containerd CNI configurations (0-containerd-nat.conf) or not.

## EXAMPLES

### Example 1: Initializes buildkitd service with the defaults

```powershell
PS C:\> Register-BuildkitdService
```

Registers buildkitd with the default Containerd configurations file `0-containerd-nat.conf` if it is available.

### Example 2: Initializes buildkitd service with the defaults

```powershell
PS C:\> Register-BuildkitdService -WinCNIPath '$ENV:ProgramFiles\containerd\cni' -BuildKitPath '$ENV:ProgramFiles\Buildkit'
```

Registers buildkitd with the default Containerd configurations file `0-containerd-nat.conf` found at `$ENV:ProgramFiles\containerd\cni`.

## PARAMETERS

### -BuildKitPath

Path where BuildKit is installed. If not provided, it defaults to BuildKit path in the environment path variable or `$Env:ProgramFiles\Buildkit`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $Env:ProgramFiles\Buildkit
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Bypass confirmation to register buildkitd service

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

Specify to start Buildkitd service after registration is complete

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

### -WinCNIPath

Path where Windows CNI plugin is installed.
If not provided, it defaults to Containerd path in the environment path variable or `$Env:ProgramFiles\Containerd`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: $Env:ProgramFiles\Containerd
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

## NOTES

When the `0-containerd-nat.conf` does not exist, the user is prompted to register buildkitd service with or without this file.

```Output
Buildkit conf file not found at ~\cni\conf\0-containerd-nat.conf.
Do you want to register buildkit service without Containerd cni configuration?
[Y] Yes  [N] No  [?] Help (default is "Y"):
```

- If a user enters `Y` (default), the user consents to register buildkitd service without the default Containerd NAT configuration file.
- If a user enters `N`, buildkitd service is not registered and the user has to register the service themselves.

## RELATED LINKS

- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Install-Buildkit](Install-Buildkit.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-Buildkit](Uninstall-Buildkit.md)
