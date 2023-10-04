---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Get-ContainerdLatestVersion

## SYNOPSIS

Returns the latest Containerd version number.

## SYNTAX

```
Get-ContainerdLatestVersion
```

## DESCRIPTION

Returns the latest Containerd version number.

## EXAMPLES

### Example 1: Get latest Containerd version

This returns a string of the latest release version of Containerd, e.g., v1.2.0.

```powershell
PS C:\> Get-ContainerdLatestVersion
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

- [Install-Containerd](Install-Containerd.md)
- [Initialize-ContainerdService](Initialize-ContainerdService.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
