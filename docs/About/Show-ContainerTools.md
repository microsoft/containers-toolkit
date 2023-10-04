---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Show-ContainerTools

## SYNOPSIS

List container tools (Containerd, Buildkit, and Nerdctl) install status.

## SYNTAX

```
Show-ContainerTools
```

## DESCRIPTION

List container tools (Containerd, Buildkit, Nerdctl) and shows if the tool is installed, the installed version and the latest available version.

## EXAMPLES

### Example 1

```powershell
PS C:\> Show-ContainerTools
```

```Output
Tool       Installed Version LatestVersion
----       --------- ------- -------------
containerd      True v1.7.7  v1.7.7
buildkit        True v0.12.2 v0.12.2
nerdctl         True unknown v1.6.1
```

## OUTPUTS

### [System.Array](https://learn.microsoft.com/en-us/dotnet/api/system.array?view=net-7.0)

Returns an array of [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject?view=powershellsdk-7.3.0),

| Name | Type | Description |
| -------- | ------- | ------- |
|Tool| String | Name of the container tool. Either Containerd, Buildkit, or Nerdctl. |
|Installed| Boolean | Specfies whether the tool is installed or not. |
|Version| String | Installed version. |
|LatestVersion| String | Latest available version |

## NOTES

This information may not be accurate if the tools have been installed in a different location and/or the paths have not been added to environment path

## RELATED LINKS
[Container Tools For Windows](ContainerToolsForWindows.md)
