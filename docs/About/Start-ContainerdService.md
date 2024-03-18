---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Start-ContainerdService

## SYNOPSIS

Starts Containerd service.

## SYNTAX

```
Start-ContainerdService
```

## DESCRIPTION

Starts Containerd service and waits for 30 seconds for the service to start. If the service does not start within the this time, execution terminates with an error.

## EXAMPLES

### Example 1

Start Containerd Service.

```powershell
PS C:\> Start-ContainerdService
```

## RELATED LINKS

- [Start-Service](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-service?view=powershell-7.3)
- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Install-Containerd](Install-Containerd.md)
- [Register-ContainerdService](Register-ContainerdService.md)
- [Stop-ContainerdService](Stop-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
