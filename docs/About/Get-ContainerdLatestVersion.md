---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Get-ContainerdLatestVersion

## SYNOPSIS

Gets the latest Containerd version number.

## SYNTAX

```
Get-ContainerdLatestVersion
```

## DESCRIPTION

Uses GitHub API to get the latest Containerd release version from the containerd/containerd GitHub repository.

## EXAMPLES

### Example 1: Get latest Containerd version

This returns a string of the latest release version of Containerd, e.g., v1.2.0.

```powershell
PS C:\> Get-ContainerdLatestVersion

    v1.2.0
```

## PARAMETERS

## INPUTS

## OUTPUTS

### String

This is a string of the latest Containerd release version.

## RELATED LINKS

- [Install-Containerd](Install-Containerd.md)
- [Register-ContainerdService](Register-ContainerdService.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
