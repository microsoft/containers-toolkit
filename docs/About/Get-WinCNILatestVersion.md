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

```
Get-WinCNILatestVersion
```

## DESCRIPTION

Uses GitHub API to get the latest Windows CNI plugin release version from the microsoft/windows-container-networking repository.

## EXAMPLES

### Example 1: Get latest nerdctl version

This returns a string of the latest release version of Windows CNI, e.g., v1.2.0.

```powershell
PS C:\> Get-WinCNILatestVersion
```

```Output
v1.2.0
```

### String

This is a string of the latest Windows CNI version release version.

## RELATED LINKS

- [Install-WinCNIPlugin](Install-WinCNIPlugin.md)
- [Uninstall-WinCNIPlugin](Uninstall-WinCNIPlugin.md)
- [Initialize-NatNetwork](Initialize-NatNetwork.md)
