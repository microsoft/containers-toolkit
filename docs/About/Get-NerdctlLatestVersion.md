---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Get-NerdctlLatestVersion

## SYNOPSIS

Gets the latest nerdctl version number.

## SYNTAX

```
Get-NerdctlLatestVersion
```

## DESCRIPTION

Uses GitHub API to get the latest nerdctl release version from the containerd/nerdctl GitHub repository.

## EXAMPLES

### Example 1: Get latest nerdctl version

This returns a string of the latest release version of nerdctl, e.g., v1.2.0.

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

This is a string of the latest nerdctl release version.

## RELATED LINKS

- [Install-Nerdctl](Install-Nerdctl.md)
- [Uninstall-Nerdctl](Uninstall-Nerdctl.md)
