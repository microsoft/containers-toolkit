---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Get-WinCNILatestVersion

## SYNOPSIS

Gets the latest Windows CNI version number.

## SYNTAX

```Text
Get-WinCNILatestVersion [-Repo <String>]
```

## DESCRIPTION

Uses GitHub API to get the latest Windows CNI plugin release version from the [_microsoft/windows-container-networking_](https://github.com/microsoft/windows-container-networking) repository or [_containernetworking/plugins_](https://github.com/containernetworking/plugins) repository.

## EXAMPLES

### Example 1: Get latest nerdctl version

This returns a string of the latest release version of Windows CNI, e.g., v1.2.0.

```powershell
PS C:\> Get-WinCNILatestVersion

    v1.2.0
```

## PARAMETERS

### -Repo

Source repository for the CNI plugins. Accepted values are 'microsoft/windows-container-networking' and 'containernetworking/plugins'.

```yaml
Type: String
Parameter Sets: (All)
Aliases: SourceRepo, Repository

Required: False
Position: Named
Default value: microsoft/windows-container-networking
Accept pipeline input: False
Accept wildcard characters: False
```

## OUTPUTS

### String

This is a string of the latest CNI plugins release version.

## RELATED LINKS

- [Install-WinCNIPlugin](Install-WinCNIPlugin.md)
- [Uninstall-WinCNIPlugin](Uninstall-WinCNIPlugin.md)
- [Initialize-NatNetwork](Initialize-NatNetwork.md)
