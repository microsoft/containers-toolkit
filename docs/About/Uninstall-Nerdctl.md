---
external help file: ContainerToolsForWindows.psm1-help.xml
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

## NOTES

## RELATED LINKS

- [Get-NerdctlLatestVersion](Get-NerdctlLatestVersion.md)
- [Install-Nerdctl](Install-Nerdctl.md)
