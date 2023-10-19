---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Initialize-BuildkitdService

## SYNOPSIS

Registers the Buildkitd service with a prompt to either register with the Containerd CNI config (0-containerd-nat.conf) or not.

## SYNTAX

```
Initialize-BuildkitdService [[-BuildKitPath] <String>] [[-WinCNIPath] <String>] [<CommonParameters>]
```

## DESCRIPTION

Registers the Buildkitd service with a prompt to either register with the Containerd CNI config (0-containerd-nat.conf) or not.

## EXAMPLES

### Example 1: Initializes Buildkitd service with the defaults

```powershell
PS C:\> Initialize-BuildkitdService
```

Registers buildkitd with the default containerd configurations file `0-containerd-nat.conf` if it is available.

### Example 2: Initializes Buildkitd service with the defaults

```powershell
PS C:\> Initialize-BuildkitdService -WinCNIPath '$ENV:ProgramFiles\containerd\cni' -BuildKitPath '$ENV:ProgramFiles\Buildkit'
```

Registers buildkitd with the default containerd configurations file `0-containerd-nat.conf` found at `$ENV:ProgramFiles\containerd\cni`.

## PARAMETERS

### -BuildKitPath

Path where Buildkit is installed. If not provided, it defaults to Buildkit path in the environment path variable or `$Env:ProgramFiles\Buildkit`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: Buildkit path in the environment path variable or $Env:ProgramFiles\Buildkit
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIPath

Path where Windows CNI plugin is installed. If not provided, it defaults to Containerd path in the environment path variable or `$Env:ProgramFiles\Containerd`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Containerd path in the environment path variable or $Env:ProgramFiles\Containerd
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

## NOTES

When the `0-containerd-nat.conf` does not exist, the user is prompted to register buildkitd service with or without this file.

```Output
Buildkit conf file not found at ~\cni\conf\0-containerd-nat.conf.
Do you want to register buildkit service without containerd cni configuration?
[Y] Yes  [N] No  [?] Help (default is "Y"):
```

- If a user enters `Y` (default), the user consents to register buildkitd service without the default containerd NAT configuration file.
- If a user enters `N`, buildkitd service is not registered and the user has to register the service themselves.

## RELATED LINKS

- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Install-Buildkit](Install-Buildkit.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-Buildkit](Uninstall-Buildkit.md)
