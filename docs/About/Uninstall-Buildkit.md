---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Uninstall-Buildkit

## SYNOPSIS

Uninstalls BuildKit.

## SYNTAX

```
Uninstall-Buildkit [[-Path] <String>] [<CommonParameters>]
```

## DESCRIPTION

To uninstall BuildKit, this command stops buildkitd service and unregisters buildkitd service. The BuildKit directory is then deleted and BuildKit is removed from the environment path.

## EXAMPLES

### Example 1

Uninstall BuildKit from the default path.

```powershell
PS C:\> Uninstall-Buildkit
```

## PARAMETERS

### -Path

BuildKit path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: The Buildkit path in the environment path variable or `$Env:ProgramFiles\Buildkit`
Accept pipeline input: False
Accept wildcard characters: False
```

## RELATED LINKS

- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Install-Buildkit](Install-Buildkit.md)
- [Register-BuildkitdService](Register-BuildkitdService.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
