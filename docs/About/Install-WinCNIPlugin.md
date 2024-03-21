---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Install-WinCNIPlugin

## SYNOPSIS

Downloads and installs Windows CNI plugin.

## SYNTAX

```
Install-WinCNIPlugin [[-WinCNIVersion] <String>] [[-WinCNIPath] <String>] [-Force] [-Confirm] [-WhatIf]
 [<CommonParameters>]
```

## DESCRIPTION

Downloads Windows CNI plugin from [windows-container-networking](https://github.com/microsoft/windows-container-networking/releases) and installs it in the specified location.

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

### -Confirm

Prompts for confirmation before running the cmdlet. For more information, see the following articles:

- [about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#confirmpreference)
- [about_Functions_CmdletBindingAttribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-7.4#confirmimpact)

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

### -Force

Installs Windows CNI plugins even if the tool already exists at the specified path.

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

### -WinCNIPath

Location to install Windows CNI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Path where containerd is installed or `$Env:ProgramFiles\Containerd`
Accept pipeline input: False
Accept wildcard characters: False
```

### -WinCNIVersion

Windows CNI plugin version to use. Defaults to latest version.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: Latest version
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

- [Get-WinCNILatestVersion](Get-WinCNILatestVersion.md)
- [Initialize-NatNetwork](Initialize-NatNetwork.md)
