---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Uninstall-Nerdctl

## SYNOPSIS

Uninstalls Nerdctl.

## SYNTAX

```
Uninstall-Nerdctl [[-Path] <String>] [<CommonParameters>]
```

## DESCRIPTION

To uninstall Nerdctl, the Nerdctl directory is deleted and Nerdctl is removed from the environment path.

## EXAMPLES

### Example 1

Uninstall Nerdctl from the default path.

```powershell
PS C:\> Uninstall-Nerdctl
```

## PARAMETERS

### -Path

Nerdctl path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: The Nerdctl path in the environment path variable or $Env:ProgramFiles\Nerdctl
Accept pipeline input: False
Accept wildcard characters: False
```

## RELATED LINKS

- [Get-NerdctlLatestVersion](Get-NerdctlLatestVersion.md)
- [Install-Nerdctl](Install-Nerdctl.md)
