---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Get-WinCNILatestVersion

## SYNOPSIS

Returns the latest Windows CNI version number.

## SYNTAX

```
Get-WinCNILatestVersion
```

## DESCRIPTION

Returns the latest Windows CNI version number.

## EXAMPLES

### Example 1: Get latest Nerdctl version

This returns a string of the latest release version of Windows CNI, e.g., v1.2.0.

```powershell
PS C:\> Get-WinCNILatestVersion
```

```Output
v1.2.0
```

## PARAMETERS

## INPUTS

### None

## OUTPUTS

### [String](https://learn.microsoft.com/en-us/dotnet/api/system.string?view=net-7.0)

## RELATED LINKS

- [Install-WinCNIPlugin](Install-WinCNIPlugin.md)
- [Initialize-NatNetwork](Initialize-NatNetwork.md)
