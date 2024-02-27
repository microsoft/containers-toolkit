---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Show-ContainerTools

## SYNOPSIS

List container tools (Containerd, BuildKit, and nerdctl) install status.

## SYNTAX

```
Show-ContainerTools [-Latest] [<CommonParameters>]
```

## DESCRIPTION

List container tools (Containerd, BuildKit, nerdctl) and shows if the tool is installed, the installed version and the latest available version.

## EXAMPLES

### Example 1

```powershell
PS C:\> Show-ContainerTools -Latest
```

```Output
Tool       Installed Version LatestVersion
----       --------- ------- -------------
containerd      True v1.7.7  v1.7.7
buildkit        True v0.12.2 v0.12.2
nerdctl         True unknown v1.6.1
```

## PARAMETERS

### -Latest

Show latest release version

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## OUTPUTS

### [System.Array](https://learn.microsoft.com/en-us/dotnet/api/system.array?view=net-7.0)

Returns an array of [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject?view=powershellsdk-7.3.0),

| Name | Type | Description |
| -------- | ------- | ------- |
| Tool | String | Name of the container tool. Either Containerd, BuildKit, or nerdctl. |
| Installed | Boolean | Specifies whether the tool is installed or not. |
| Version | String | Installed version. |
| LatestVersion | String | Latest available version |
| Daemon | String | Tools daemon, e.g., containerd and buildkitd |
| Daemon  Status| String | Specifies the status of the daemon: running, stopped, unregistered |

## NOTES

1. This information may not be accurate if a tool's paths has not been added to environment path.
2. A daemon's status could be unavailable if it has not been installed

## RELATED LINKS

- [Container Tools For Windows](Containers-Toolkit.md)
