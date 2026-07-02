BeforeAll {
    . ./event-parser.ps1
}

Describe "Basic event dispatching" {
    It "parses JSON data into PSCustomObject" {
        $parser = New-EventParser
        $parser.Invoke('data: {"key":"value"}') | Should -BeNullOrEmpty
        $result = $parser.Invoke("")
        $result.Data | Should -BeOfType [PSCustomObject]
        $result.Data.key | Should -Be "value"
    }

    It "parses event type field" {
        $parser = New-EventParser
        $parser.Invoke("event: myEvent") | Should -BeNullOrEmpty
        $parser.Invoke("data: {}") | Should -BeNullOrEmpty
        $result = $parser.Invoke("")
        $result.EventType | Should -Be "myEvent"
    }

    It "parses event id field" {
        $parser = New-EventParser
        $parser.Invoke("id: abc123") | Should -BeNullOrEmpty
        $parser.Invoke("data: {}") | Should -BeNullOrEmpty
        $result = $parser.Invoke("")
        $result.EventId | Should -Be "abc123"
    }
}

Describe "Non-JSON data (regression for Fix 1)" {
    It "does not throw and returns raw string for plain text data" {
        $parser = New-EventParser
        $parser.Invoke("data: hello world") | Should -BeNullOrEmpty
        { $result = $parser.Invoke("") } | Should -Not -Throw
        $parser2 = New-EventParser
        $parser2.Invoke("data: hello world")
        $result = $parser2.Invoke("")
        $result.Data | Should -Be "hello world"
    }

    It "returns a number for numeric JSON data" {
        $parser = New-EventParser
        $parser.Invoke("data: 42") | Should -BeNullOrEmpty
        $result = $parser.Invoke("")
        $result.Data | Should -Be 42
    }
}

Describe "id null-char check (regression for Fix 2)" {
    It "sets EventId for a valid id value" {
        $parser = New-EventParser
        $parser.Invoke("id: valid-id") | Should -BeNullOrEmpty
        $parser.Invoke("data: {}") | Should -BeNullOrEmpty
        $result = $parser.Invoke("")
        $result.EventId | Should -Be "valid-id"
    }

    It "does not update EventId when value contains a null character" {
        $parser = New-EventParser
        $nullChar = [char]0
        $parser.Invoke("id: bad$nullChar") | Should -BeNullOrEmpty
        $parser.Invoke("data: {}") | Should -BeNullOrEmpty
        $result = $parser.Invoke("")
        $result.EventId | Should -BeNullOrEmpty
    }
}

Describe "Comments ignored" {
    It "ignores comment lines (does not affect data)" {
        $parser = New-EventParser
        $parser.Invoke(": this is a comment") | Should -BeNullOrEmpty
        $parser.Invoke("data: {}") | Should -BeNullOrEmpty
        $result = $parser.Invoke("")
        $result.Data | Should -BeOfType [PSCustomObject]
    }
}
