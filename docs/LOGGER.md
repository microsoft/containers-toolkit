# Containers Toolkit Logger

A static PowerShell logger designed for use across module files within the **Containers Toolkit**. It supports configurable log levels, console output, optional log file writing, and integration with the **Windows Event Log**.

## Key Features

- Supports multiple log levels: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `FATAL`.
- Logs messages to the **console**, **optional log file**, and the **Windows Event Log** (for applicable levels).
- Minimum log level is determined dynamically from the `CTK_LOG_LEVEL` environment variable or PowerShell’s `$DebugPreference`.
- Allows suppressing console output using the SKIP_CTK_LOGGING environment variable — similar to running in a quiet mode.

## Debug Logging Behavior

- `DEBUG` messages are only shown in the console if:

  - `$DebugPreference` is not `"SilentlyContinue"`, **or**
  - the environment variable `CTK_LOG_LEVEL` is set to `"DEBUG"`.
- `DEBUG` messages are **not** written to the Windows Event Log.

## Usage

To use the logger, you need to import the module (if it is not already imported).

```PowerShell
using using module "..\Private\logger.psm1"
```

## Log Levels

The logger supports the following log levels:

### Info level

```PowerShell
[Logger]::Log("This is a test message") # Defaults to INFO level
[Logger]::Log("This is a test message", "INFO")
[Logger]::Info("This is a test message")

INFO:   [2025-05-20T08:23:12Z] [Install-Nerdctl:42]: "This is a test message"
```

### Debug level

To enable `DEBUG` level logging, set the environment variable `CTK_LOG_LEVEL` to `"DEBUG"` or ensure `$DebugPreference` is not set to `"SilentlyContinue"`.

```PowerShell
[Logger]::Log("This is a test message", "DEBUG")
[Logger]::Debug("This is a test message")

DEBUG:   [2025-05-20T08:23:12Z] [Install-Nerdctl:42]: "This is a test message"
```

### Warning level

```PowerShell
[Logger]::Log("This is a test message", "WARNING")
[Logger]::Warning("This is a test message")

WARNING:   [2025-05-20T08:23:12Z] [Install-Nerdctl:42]: "This is a test message"
```

### Error level

```PowerShell
[Logger]::Log("This is a test message", "ERROR")
[Logger]::Error("This is a test message")

ERROR:   [2025-05-20T08:23:12Z] [Install-Nerdctl:42]: "This is a test message"
```

### Fatal level

Throws a terminating error.

```PowerShell
[Logger]::Log("This is a test message", "FATAL")
[Logger]::Fatal("This is a test message")


FATAL:   [2025-05-20T08:23:12Z] [Install-Nerdctl:42]: "This is a test message"
Exception: Uncaught Critical message
```

## Environment Variables

The logger uses the following environment variables to configure its behavior:

| Variable                | Description                                                                                                                                                                                                                                  |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `$env:CTK_LOG_LEVEL`    | Sets the minimum log level. Accepted values are: `DEBUG`, `INFO`, `WARNING`, `ERROR`, and `FATAL`. Defaults to `INFO` if not set.                                                                                                            |
| `$env:CTK_LOG_FILE`     | Path to a file where logs should be written. If not set, logs will be written to the console and Windows Event Log (for applicable levels). **Note:** The logger does not handle log file rotation or cleanup—use external tooling for that. |
| `$env:SKIP_CTK_LOGGING` | If set to `"true"`, suppresses console output for all log levels except `DEBUG` (when `$DebugPreference` is not `"SilentlyContinue"`). Logging to file (if set) and to the Windows Event Log (excluding `DEBUG`) still occurs.               |
