---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Get-BuildkitLatestVersion

## SYNOPSIS

Gets the latest Buildkit version number.

## SYNTAX

```
Get-BuildkitLatestVersion
```

## DESCRIPTION

Uses GitHub APIs to get the latest BuildKit release version from the moby/buildkit GitHub repository.

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

## OUTPUTS

### String

This is a string of the latest Buildkit release version.

## RELATED LINKS

- [Install-Buildkit](Install-Buildkit.md)
- [Register-BuildkitdService](Register-BuildkitdService.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-Buildkit](Uninstall-Buildkit.md)
