---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Initialize-ContainerdService

## SYNOPSIS

Create a default containerd configuration file called `config.toml` at the Containerd path and registers the containerd service.

## SYNTAX

```
Initialize-ContainerdService [[-ContainerdPath] <String>] [<CommonParameters>]
```

## DESCRIPTION

Create a default containerd configuration file called `config.toml` at the Containerd path and registers the containerd service.

## EXAMPLES

### Example 1: Using default Containerd path

Creates the config.toml file at the default containerd path and registers the containerd service.

```powershell
PS C:\> Initialize-ContainerdService
```

### Example 2: Using custom path

Creates the config.toml file at the provided containerd path and registers the containerd service. If containerd does not exist at the provided path, execution fails with an error.

```powershell
PS C:\> Initialize-ContainerdService -ContainerdPath 'C:\Test\Path\containerd'
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
Default value: The containerd path in the environment path variable or $Env:ProgramFiles\containerd
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

## NOTES

## RELATED LINKS

- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Install-Containerd](Install-Containerd.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
