---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Get-NerdctlLatestVersion

## SYNOPSIS

Returns the latest Nerdctl version number.

## SYNTAX

```
Get-NerdctlLatestVersion
```

## DESCRIPTION

Returns the latest Nerdctl version number.

## EXAMPLES

### Example 1: Get latest Nerdctl version

This returns a string of the latest release version of Nerdctl, e.g., v1.2.0.

```powershell
PS C:\> Get-NerdctlLatestVersion
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

- [Install-Nerdctl](Install-Nerdctl.md)
- [Uninstall-Nerdctl](Uninstall-Nerdctl.md)
