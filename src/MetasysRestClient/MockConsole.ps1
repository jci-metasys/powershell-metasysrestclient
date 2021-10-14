class MockConsole {
    static [string] $MetasysHostPrompt = "Metasys Host"
    static [string] $UserNamePrompt = "UserName"
    static [string] $PasswordPrompt = "Password"
    static [string] $PathPrompt = "Path"

    static [String] $DefaultMetasysHost = "testhost"
    static [String] $DefaultUserName = "testuser"
    static [SecureString] $DefaultPassword = (ConvertTo-SecureString "testpassword" -AsPlainText)
    static [string] $DefaultPath = "/objects"

    [Hashtable]$Inputs = @{ }

    MockConsole() {
        $this.Inputs[[MockConsole]::MetasysHostPrompt] = [MockConsole]::DefaultMetasysHost
        $this.Inputs[[MockConsole]::UserNamePrompt] = [MockConsole]::DefaultUserName
        $this.Inputs[[MockConsole]::PasswordPrompt] = [MockConsole]::DefaultPassword
        $this.Inputs[[MockConsole]::PathPrompt] = [MockConsole]::DefaultPath
    }

    MockConsole([String]$SiteHost = $DefaultSiteHost, [string]$UserName = $DefaultUserName,
        [SecureString]$Password = $DefaultPassword) {

        $this.Inputs[[MockConsole]::MetasysHostPrompt] = $SiteHost
        $this.Inputs[[MockConsole]::UserNamePrompt] = $UserName
        $this.Inputs[[MockConsole]::PasswordPrompt] = $Password
    }

    [void] SetResponse([string]$Prompt, [object]$Response) {
        $this.Inputs[$Prompt] = $Response
    }

    [string] GetResponse([string]$Prompt) {
        return $this.Inputs[$Prompt]
    }

    [Object] ReadHost([String]$Prompt) {
        return $this.Inputs[$Prompt]
    }

    [String]GetUserName() {
        return $this.Inputs[[MockConsole]::UserNamePrompt]
    }

    [String]GetPasswordAsPlainText() {
        return $this.Inputs[[MockConsole]::PasswordPrompt] | ConvertFrom-SecureString -AsPlainText
    }

    [SecureString]GetPassword() {
        return $this.Inputs[[MockConsole]::PasswordPrompt]
    }

    [String]GetMetasysHost() {
        return $this.Inputs[[MockConsole]::MetasysHostPrompt]
    }
}

