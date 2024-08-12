---
external help file: containers-toolkit-help.xml
Module Name: containers-toolkit
online version:
schema: 2.0.0
---

# Install-ContainerTools

## SYNOPSIS

Downloads and installs container tool (Containerd, BuildKit, and nerdctl).

## SYNTAX

```
Install-ContainerTools [[-ContainerDVersion] <String>] [[-BuildKitVersion] <String>]
 [[-NerdCTLVersion] <String>] [[-InstallPath] <String>] [[-DownloadPath] <String>] [-Force] [-RegisterServices]
 [-Confirm] [-WhatIf] [<CommonParameters>]
```

## DESCRIPTION

Downloads container tool (Containerd, BuildKit, and nerdctl) asynchronously and installs them at the specified location.

## EXAMPLES

### Example 1: Using defaults

Install the latest versions of Containerd, BuildKit, and nerdctl at the default path

```powershell
PS C:\> Install-ContainerTools
```

### Example 2: Download Containerd version 1.6.8 and default nerdctl and BuildKit versions

Download Containerd version 1.6.8 and default nerdctl and BuildKit versions

```powershell
PS C:\> Install-ContainerTools -ContainerDVersion 1.6.8
```

### Example 3: Register and Start Containerd and Buildkitd services and set up NAT network

Register and Start Containerd and Buildkitd services and set up NAT network

```powershell
PS C:\> Install-ContainerTools -RegisterServices
```

## PARAMETERS

### -BuildKitVersion

BuildKit version to install

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Latest version
Accept pipeline input: False
Accept wildcard characters: False
```

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

### -ContainerDVersion

Containerd version to install

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

### -DownloadPath

Path to download files. Defaults to user's Downloads folder, `$HOME\Downloads`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: $HOME\Downloads
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Force install the tools even if they already exists at the specified path.

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

### -RegisterServices

Register and Start Containerd and Buildkitd services and set up NAT network.

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

### -InstallPath

Path to Install files. Defaults to Program Files, `$Env:ProgramFiles`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: $Env:ProgramFiles
Accept pipeline input: False
Accept wildcard characters: False
```

### -NerdCTLVersion

nerdctl version to install

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

- [Install-Containerd](Install-Containerd.md)
- [Install-BuildKit](Install-BuildKit.md)
- [Install-Nerdctl](Install-Nerdctl.md)
