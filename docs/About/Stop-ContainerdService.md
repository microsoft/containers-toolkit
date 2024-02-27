---
external help file: Containers-Toolkit-help.xml
Module Name: Containers-Toolkit
online version:
schema: 2.0.0
---

# Stop-ContainerdService

## SYNOPSIS

Stops Containerd service.

## SYNTAX

```
Stop-ContainerdService
```

## DESCRIPTION

Stops Containerd service and waits for 30 seconds for the service to stop. If the service does not stop within the this time, execution terminates with an error.

## EXAMPLES

### Example 1

Stop Containerd Service.

```powershell
PS C:\> Stop-ContainerdService
```

## RELATED LINKS

- [Stop-Service](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/stop-service?view=powershell-7.3)
- [Get-ContainerdLatestVersion](Get-ContainerdLatestVersion.md)
- [Install-Containerd](Install-Containerd.md)
- [Register-ContainerdService](Register-ContainerdService.md)
- [Start-ContainerdService](Start-ContainerdService.md)
- [Uninstall-Containerd](Uninstall-Containerd.md)
