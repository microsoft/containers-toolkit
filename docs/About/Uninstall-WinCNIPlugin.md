---
external help file: ContainerNetworkTools.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Uninstall-WinCNIPlugin

## SYNOPSIS

Uninstall Windows CNI plugins.

## SYNTAX

```
Uninstall-WinCNIPlugin [[-Path] <String>] [<CommonParameters>]
```

## DESCRIPTION

Uninstall Windows CNI plugins from the default or provided path. The default path is `$ENV:ProgramFiles\Containerd\cni`.

## EXAMPLES

### Example 1

Uninstalls WinCNIPlugins from the default path, `$ENV:ProgramFiles\Containerd\cni`

```powershell
PS C:\> Uninstall-WinCNIPlugin 
```

## PARAMETERS

### -Path

Windows CNI plugin path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: $ENV:ProgramFiles\Containerd\cni
Accept pipeline input: False
Accept wildcard characters: False
```

## RELATED LINKS

- [Get-WinCNILatestVersion](Get-WinCNILatestVersion.md)
- [Install-WinCNIPlugin](Install-WinCNIPlugin.md)
- [Initialize-NatNetwork](Initialize-NatNetwork.md)
