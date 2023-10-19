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
