###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

<#
.SYNOPSIS
Sign PowerShell scripts (ps1, psm1, psd1, ps1xml) using AzureSignTool.


.PARAMETER Directory
Directory containing PowerShell script files.
Defaults to the current working directory (.).

.PARAMETER AzureKeyVaultUrl
The URL to an Azure Key Vault.

.PARAMETER AzureKeyVaultClientId
The Client ID (Application ID) to authenticate to the Azure Key Vault.

.PARAMETER AzureKeyVaultClientSecret
The client secret of your Azure application to authenticate to the Azure Key Vault.

.PARAMETER AzureKeyVaultTenantId
The Tenant Id to authenticate to the Azure Key Vault.

.PARAMETER AzureKeyVaultCertificate
The name of the certificate in Azure Key Vault.

#>


[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [String]$Directory = ".",
    [Parameter(Mandatory = $true)]
    [String]$AzureKeyVaultUrl,
    [Parameter(Mandatory = $true)]
    [String]$AzureKeyVaultClientId,
    [Parameter(Mandatory = $true)]
    [String]$AzureKeyVaultClientSecret,
    [Parameter(Mandatory = $true)]
    [String]$AzureKeyVaultTenantId,
    [Parameter(Mandatory = $true)]
    [String]$AzureKeyVaultCertificate
)

$Script:Directory = $Directory
$Script:AzureKeyVaultUrl = $AzureKeyVaultUrl
$Script:AzureKeyVaultClientId = $AzureKeyVaultClientId
$Script:AzureKeyVaultClientSecret = $AzureKeyVaultClientSecret
$Script:AzureKeyVaultTenantId = $AzureKeyVaultTenantId
$Script:AzureKeyVaultCertificate = $AzureKeyVaultCertificate

function Invoke-ExecutableCommand {
    param (
        [parameter(Mandatory)]
        [String] $executable,
        [parameter(Mandatory)]
        [String] $arguments
    )

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $executable
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()

    return $p
}

function Invoke-AzureSignTool {
    # Get scripts to sign
    $scripts = Get-ChildItem -Path "$Script:Directory" -ErrorAction Stop -Exclude ".github" | `
        Get-ChildItem -Recurse -ErrorAction Stop | `
        Where-Object { $_.name -match "ps[d|m]?1(xml)?" }

    # Sign the scripts
    foreach ($script in $scripts) {
        Write-Output "Signing file: $($script.Name)"

        $params = @{
            'kvu' = "`"$Script:AzureKeyVaultUrl`""
            'kvi' = "`"$Script:AzureKeyVaultClientId`""
            'kvs' = "`"$Script:AzureKeyVaultClientSecret`""
            'kvt' = "`"$Script:AzureKeyVaultTenantId`""
            'kvc' = "`"$Script:AzureKeyVaultCertificate`""
            # timestamp-rfc3161
            'tr'  = 'http://timestamp.digicert.com '
        }

        # Convert params to string
        $arguments = "sign"
        foreach ($kv in $params.GetEnumerator()) {
            $arguments += " -$($kv.Name) $($kv.Value)"
        }

        $arguments += " -v $($script.FullName)"

        $output = Invoke-ExecutableCommand -Executable 'AzureSignTool' -Arguments $arguments
        if ($output.ExitCode -ne 0) {
            $err = $output.StandardError.ReadToEnd()
            if ([string]::IsNullOrEmpty($err)) {
                $err = $output.StandardOutput.ReadToEnd()
            }

            Write-Error "Failed to sign script $($script.Name). Error code: ($($output.ExitCode))."
            Throw $err
        }
    }
}

# Execute
Invoke-AzureSignTool
