###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

<#
.Synopsis
    Validates JSON content against a specified schema.

.Description
    This module provides a function to validate JSON strings against a JSON schema.
    It uses Newtonsoft.Json and Newtonsoft.Json.Schema libraries for parsing and validation.
    It is used only when running in a PowerShell v5.1 or earlier environments that
    do not have the built-in `Test-Json` cmdlet available.
    `Test-Json` cmdlet is available in PowerShell 7+.
#>


class JsonValidator {
    # Static method for validating JSON against a schema
    static [bool] Validate([String]$jsonContent, [String]$schemaContent) {
        try {
            # Parse the JSON string into a JObject.
            # $jToken = [Newtonsoft.Json.Linq.JToken]::Parse($jsonContent)
            $jToken = [Newtonsoft.Json.Linq.JToken]::Parse($jsonContent)

            # Parses the JSON schema.
            # $jSchema = [Newtonsoft.Json.Schema.JSchema]::Parse($schemaContent)
            $jSchema = [Newtonsoft.Json.Schema.JSchema]::Parse($schemaContent)

            # Validate the JSON against the schema.
            $errors = New-Object System.Collections.Generic.List[string]
            # $isValid = [Newtonsoft.Json.Schema.SchemaExtensions]::IsValid($jToken, $jSchema, [ref]$errors)
            $isValid = [Newtonsoft.Json.Schema.SchemaExtensions]::IsValid($jToken, $jSchema, [ref]$errors)

            if ($isValid) {
                return $true
            }
            else {
                # Write-Host "JSON is invalid according to the schema."
                # $errors | ForEach-Object { Write-Host $_ }
                Write-Error "The JSON is not valid with the schema: $($errors -join ', ')"
                return $false
            }
        }
        catch {
            Write-Error "An error occurred during validation: $_"
            return $false
        }
    }
}


function Test-Json {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Low'
    )]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "JSON string to test for validity.")]
        [String]$Json,
        [Parameter(Mandatory = $true, HelpMessage = "A schema to validate the JSON input against.")]
        [String]$Schema
    )

    begin {
        $WhatIfMessage = "Validate JSON against schema."
    }

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $WhatIfMessage)) {
            return [JsonValidator]::Validate($Json, $Schema)
        }
        else {
            # Code that should be processed if doing a WhatIf operation
            # Must NOT change anything outside of the function / script
            return
        }
    }
}

Export-ModuleMember -Function Test-Json
