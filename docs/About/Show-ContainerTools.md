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
Show-ContainerTools [-Latest] [-ToolName <String[]>] [<CommonParameters>]
```

## DESCRIPTION

List container tools (Containerd, BuildKit, nerdctl) and shows if the tool is installed, the installed version and the latest available version.

## EXAMPLES

### Example 1

```powershell
PS C:\> Show-ContainerTools -Latest

        Tool        Installed   Version     LatestVersion
        ------      ------      ------      ------
        containerd  True        v1.7.7      v1.7.7
        buildkit    False       -           v0.12.2
        nerdctl     True        unknown     v1.6.1
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
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToolName

Displays the version of a specified tool.
If no tool is specified, it returns the versions of containerd, buildkit, and nerdctl.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Null
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

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
2. A daemon's status could be unavailable if the service has not been registered or started.
3. The latest version is fetched from the GitHub releases page of the tool.

## RELATED LINKS

- [Get-BuildkitLatestVersion](./Get-BuildkitLatestVersion.md)
- [Get-ContainerdLatestVersion](./Get-ContainerdLatestVersion.md)
- [Get-NerdctlLatestVersion](./Get-NerdctlLatestVersion.md)
- [Get-WinCNILatestVersion](./Get-WinCNILatestVersion.md)
