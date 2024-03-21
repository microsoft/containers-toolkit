---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Uninstall-Nerdctl

## SYNOPSIS

Uninstalls nerdctl.

## SYNTAX

```
Uninstall-Nerdctl [[-Path] <String>] [-Force] [-WhatIf] [<CommonParameters>]
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

### -Force

Bypass confirmation to uninstall nerdctl

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

nerdctl path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: The nerdctl path in the environment path variable or $Env:ProgramFiles\nerdctl
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet isn't run.

```yaml
Type: SwitchParameter
Parameter Sets: Setup
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## RELATED LINKS

- [Get-NerdctlLatestVersion](Get-NerdctlLatestVersion.md)
- [Install-Nerdctl](Install-Nerdctl.md)
