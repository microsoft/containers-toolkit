---
external help file: ContainerToolsForWindows.psm1-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Start-BuildkitdService

## SYNOPSIS

Starts Buildkitd service.

## SYNTAX

```
Start-BuildkitdService
```

## DESCRIPTION

Starts Buildkitd service and waits for 30 seconds for the service to start. If the service does not start within the this time, execution terminates with an error.

## EXAMPLES

### Example 1

Start Buildkitd Service.

```powershell
PS C:\> Start-BuildkitdService
```

## PARAMETERS 

## INPUTS

### None

## OUTPUTS

## NOTES

## RELATED LINKS

- [Start-Service](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-service?view=powershell-7.3)
- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Install-Buildkit](Install-Buildkit.md)
- [Initialize-BuildkitdService](Initialize-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-Buildkit](Uninstall-Buildkit.md)
