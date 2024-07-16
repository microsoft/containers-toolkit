###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################


class ChoiceClass {
    [Int]$MockedChoice

    ChoiceClass(
        [Int]$MockedChoice
    ) {
        $this.MockedChoice = $MockedChoice
    }

    [Int]PromptForChoice ($caption, $message, $choices, $defaultChoice) {
        return $this.MockedChoice
    }
}

class UITest {
    [Int]$MockedChoice
    [ChoiceClass]$UI

    UITest(
        [Int]$MockedChoice
    ) {
        $this.MockedChoice = $MockedChoice
        $this.UI = [ChoiceClass]::new($this.MockedChoice)
    }
}

class MockService {
    [String]$Name
    [String]$Status = "Running"

    MockService(
        [String]$ServiceName
    ) {
        $this.Name = $ServiceName
    }

    [void]WaitForStatus ($status, $duration) { }
}


# To avoid CommandNotFoundException in nodes that do not contain these PS cmdlets,
# we create mock functions instead
function New-HNSNetwork {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions",
        '',
        Justification = 'Mock function for testing'
    )]
    [CmdletBinding()]
    param(
        $JsonString,
        $Type,
        $Name,
        $AddressPrefix,
        $Gateway,
        $SubnetPolicies,
        $IPv6,
        $DNSServer,
        $AdapterName,
        $AdditionalParams,
        $NetworkSpecificParams
    )

    # Prevent PSReviewUnusedParameter false positive
    # https://github.com/PowerShell/PSScriptAnalyzer/issues/1472#issuecomment-1544510319
    $Null = $JsonString, $Type, $Name, $AddressPrefix, $Gateway, $SubnetPolicies, $IPv6, $DNSServer, $AdapterName, $AdditionalParams, $NetworkSpecificParams

    # Do nothing
}


Export-ModuleMember -Function New-HNSNetwork
