---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Install-WinCNIPlugin

## SYNOPSIS

Downloads and installs CNI plugin.

## SYNTAX

```
Install-WinCNIPlugin [[-WinCNIVersion] <String>] [[-WinCNIPath] <String>] [-SourceRepo <String>]
 [-OSArchitecture <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Downloads CNI plugin from [microsoft/windows-container-networking](https://github.com/microsoft/windows-container-networking/releases) or [containernetworking/plugin](https://github.com/containernetworking/plugins) and installs it in the specified location.

## EXAMPLES

### Example 1: Using defaults

Installs latest Windows CNI plugin at the default path.

```powershell
PS C:\> Install-WinCNIPlugin
```

### Example 2: Using custom values

Installs Windows CNI plugin version 0.2.0 in the default path.

```powershell
PS C:\> Install-WinCNIPlugin -WinCNIVersion "0.2.0"
```

## PARAMETERS

### -Force

Force CNI plugins uninstallation (if it exists) without any confirmation prompts.

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

### -OSArchitecture

OS architecture to download files for.
Default is `$env:PROCESSOR_ARCHITECTURE`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $env:PROCESSOR_ARCHITECTURE
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceRepo

Source of the Windows CNI plugins.
Defaults to 'microsoft/windows-container-networking'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: "microsoft/windows-container-networking"
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIPath

Location to install Windows CNI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $Env:ProgramFiles\Containerd
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIVersion

Windows CNI plugin version to use.
Defaults to latest version.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: latest
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## RELATED LINKS

- [Get-WinCNILatestVersion](Get-WinCNILatestVersion.md)
- [Initialize-NatNetwork](Initialize-NatNetwork.md)
