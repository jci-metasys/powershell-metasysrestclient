
function Read-ConfigFile {
    <#
    .Synopsis
    Read the file $HOME/.metasysrestclient and return a host entry that corresponds to the given alias.

    .DESCRIPTION


    .Example
    #>
    param(
        [string]$Alias
    )
    $config = $null
    $config = Get-Content "$HOME/.metasysrestclient" -Raw -ErrorAction SilentlyContinue
    if ($config) {
        $configs = $null
        $configs = ConvertFrom-Json $config  -ErrorAction SilentlyContinue
        if ($configs) {
            $hosts = $configs.hosts
            if ($hosts) {
                # Return the last match option
                $hostEntry = $hosts.Where{ $_.alias -eq $Alias} | Select-Object -First 1
                if ($hostEntry.psobject.properties['hostname']) {
                    $hostEntry
                }
            }
        } else {
            $path = $HOME + "/.metasysapirc"
            Write-Error "Cannot parse '$path' file. Expected valid JSON."
            Exit
        }
    }
}

    <#
    .Synopsis
    Read the file $HOME/.metasysrestclient and return the list of the aliases found.

    #>
function ReadAliases {
    $config = $null
    $config = Get-Content "$HOME/.metasysrestclient" -Raw -ErrorAction SilentlyContinue
    if ($config) {
        $configs = $null
        $configs = ConvertFrom-Json $config  -ErrorAction SilentlyContinue
        if ($configs) {
            $configs.hosts | Select-Object -ExpandProperty alias
        }
    }
}
