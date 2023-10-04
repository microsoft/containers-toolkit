---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Get-BuildkitLatestVersion

## SYNOPSIS

Returns the latest Buildkit version number.

## SYNTAX

```
Get-BuildkitLatestVersion
```

## DESCRIPTION

Returns the latest Buildkit version number.

## EXAMPLES

### Example 1: Get latest Buildkit version

This returns a string of the latest release version of BuildKit, e.g., v1.2.0.

```powershell
PS C:\> Get-BuildkitLatestVersion
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

- [Install-Buildkit](Install-Buildkit.md)
- [Initialize-BuildkitdService](Initialize-BuildkitdService.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-Buildkit](Uninstall-Buildkit.md)
