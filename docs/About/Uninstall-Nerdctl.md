---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Uninstall-Nerdctl

## SYNOPSIS

Uninstalls nerdctl.

## SYNTAX

```
Uninstall-Nerdctl [[-Path] <String>] [<CommonParameters>]
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

### -Path

nerdctl path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: The nerdctl path in the environment path variable or $Env:ProgramFiles\Nerdctl
Accept pipeline input: False
Accept wildcard characters: False
```

## RELATED LINKS

- [Get-NerdctlLatestVersion](Get-NerdctlLatestVersion.md)
- [Install-Nerdctl](Install-Nerdctl.md)
