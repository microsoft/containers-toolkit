---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Get-NerdctlLatestVersion

## SYNOPSIS

Gets the latest Nerdctl version number.

## SYNTAX

```
Get-NerdctlLatestVersion
```

## DESCRIPTION

Uses GitHub APIs to get the latest Nerdctl release version from the containerd/nerdctl GitHub repository.

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

## OUTPUTS

### String

This is a string of the latest Nerdctl release version.

## RELATED LINKS

- [Install-Nerdctl](Install-Nerdctl.md)
- [Uninstall-Nerdctl](Uninstall-Nerdctl.md)
