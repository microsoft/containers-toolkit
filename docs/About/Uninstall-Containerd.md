---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Uninstall-Containerd

## SYNOPSIS

Uninstalls Containerd.

## SYNTAX

```
Uninstall-Containerd [[-Path] <String>] [-Force] [-WhatIf] [<CommonParameters>]
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

### -Force

Bypass confirmation to uninstall Containerd

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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

- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Install-Containerd](Install-Containerd.md)
- [Register-ContainerdService](Register-ContainerdService.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
