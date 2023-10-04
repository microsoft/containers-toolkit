---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Stop-BuildkitdService

## SYNOPSIS

Stops Buildkitd service.

## SYNTAX

```
Stop-BuildkitdService
```

## DESCRIPTION

Stops Buildkitd service and waits for 30 seconds for the service to stop. If the service does not stop within the this time, execution terminates with an error.

## EXAMPLES

### Example 1

Start Buildkitd Service.

```powershell
PS C:\> Stop-BuildkitdService
```

## PARAMETERS

## INPUTS

### None

## OUTPUTS

## NOTES

## RELATED LINKS

- [Stop-Service](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/stop-service?view=powershell-7.3)
- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Install-Buildkit](Install-Buildkit.md)
- [Initialize-BuildkitdService](Initialize-BuildkitdService.md)
- [Start-BuildkitdService](Start-BuildkitdService.md)
- [Uninstall-Buildkit](Uninstall-Buildkit.md)
