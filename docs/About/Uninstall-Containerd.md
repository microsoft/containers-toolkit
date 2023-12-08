---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Uninstall-Containerd

## SYNOPSIS

Uninstalls Containerd.

## SYNTAX

```
Uninstall-Containerd [[-Path] <String>] [<CommonParameters>]
```

## DESCRIPTION

To uninstall Containerd, this function first stops Containerd service and unregisters Containerd service. The Containerd directory is then deleted and Containerd is removed from the environment path.

## EXAMPLES

### Example 1

Uninstall Containerd from the default path.

```powershell
PS C:\> Uninstall-Containerd
```

## PARAMETERS

### -Path

Containerd path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: The Containerd path in the environment path variable or `$Env:ProgramFiles\Containerd`
Accept pipeline input: False
Accept wildcard characters: False
```

## RELATED LINKS

- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Install-Containerd](Install-Containerd.md)
- [Register-ContainerdService](Register-ContainerdService.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
