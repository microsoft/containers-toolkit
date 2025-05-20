

function Get-LogMessage {
    param (
        [string]$Message,
        [ValidateSet("DEBUG", "ERROR", "INFO", "WARNING")]
        [string]$LogLevel = "INFO"
    )
    $CallStack = Get-PSCallStack
    # [0]: Get-LogMessage, [1]: New-LogMessage, [2]: Write-CTK*
    $CallerFunction = $CallStack[3]

    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffffK")
    $CommandName = $CallerFunction.InvocationInfo.MyCommand
    $ScriptLineNumber = $CallerFunction.ScriptLineNumber
    return "[$timestamp] [${CommandName}:${ScriptLineNumber}] $($LogLevel.ToUpper()): $Message"
}

function New-LogMessage {
    param (
        [string]$Message,
        [ValidateSet("DEBUG", "ERROR", "INFO", "WARNING")]
        [string]$LogLevel = "INFO"
    )
    Write-Host "LogLevel: $LogLevel"
    Write-Host "Message: $Message"
    $parsedMessage = Get-LogMessage -Message $Message -LogLevel $LogLevel
    switch ($LogLevel) {
        "DEBUG" {
            Write-Debug $parsedMessage
        }
        "ERROR" {
            $EventID = 5000
            $eventType = [System.Diagnostics.EventLogEntryType]::Error
            Write-Error $parsedMessage
        }
        "INFO" {
            $EventID = 1000
            $eventType = [System.Diagnostics.EventLogEntryType]::Information
            Write-Host $parsedMessage
        }
        "WARNING" {
            $EventID = 4000
            $eventType = [System.Diagnostics.EventLogEntryType]::Warning
            Write-Warning $parsedMessage
        }
    }

    #  User-defined environment variable to skip logging
    if ($env:SKIP_CTK_LOGGING) {
        return
    }

    # Log to file if CTK_LOG_FILE is set
    if ($env:CTK_LOG_FILE) {
        $parsedMessage | Out-File -FilePath $env:CTK_LOG_FILE -Append
        return
    }

    # Default: Log to event log (non-DEBUG messages)
    if ($LogLevel -ne "DEBUG") {
        $eventLog = "Application"
        $Source = "Containers-Toolkit"
        # Create the event log source if it doesn't exist
        if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
            New-EventLog -LogName $eventLog -Source $Source
        }
        Write-EventLog -LogName $eventLog -Source $Source -EventId $EventID -EntryType $eventType -Message $parsedMessage
    }
}

function Write-CTKDebug {
    param (
        [string]$Message
    )
    New-LogMessage -Message $Message -LogLevel "DEBUG"
}

function Write-CTKError {
    param (
        [string]$Message
    )
    New-LogMessage -Message $Message -LogLevel "ERROR"
}

function Write-CTKInfo {
    param (
        [string]$Message
    )
    New-LogMessage -Message $Message -LogLevel "INFO"
}
function Write-CTKWarning {
    param (
        [string]$Message
    )
    New-LogMessage -Message $Message -LogLevel "WARNING"
}


Export-ModuleMember -Function Write-CTK*
