---
external help file: ContainerToolsForWindows-help.xml
Module Name: ContainerToolsForWindows
online version:
schema: 2.0.0
---

# Start-BuildkitdService

## SYNOPSIS

Starts buildkitd service.

## SYNTAX

```
Start-BuildkitdService
```

## DESCRIPTION

Starts buildkitd service and waits for 30 seconds for the service to start. If the service does not start within the this time, execution terminates with an error.

## EXAMPLES

### Example 1

Start buildkitd Service.

```powershell
PS C:\> Start-BuildkitdService
```

## RELATED LINKS

- [Start-Service](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-service?view=powershell-7.3)
- [Get-BuildkitLatestVersion](Get-BuildkitLatestVersion.md)
- [Install-Buildkit](Install-Buildkit.md)
- [Register-BuildkitdService](Register-BuildkitdService.md)
- [Stop-BuildkitdService](Stop-BuildkitdService.md)
- [Uninstall-Buildkit](Uninstall-Buildkit.md)
