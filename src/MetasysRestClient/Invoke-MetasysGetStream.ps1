# https://www.reddit.com/r/PowerShell/comments/g8p8ya/powershell_and_rest_serversent_events_api_sse_not/

function Invoke-MetasysGetStream {
    <#
        .SYNOPSIS
            Connects to the /stream resource on a Metasys site to listen for events

        .DESCRIPTION
            Some of the operations on a Metasys site can send events to a client. For example, one can sign up for Change of Value updates for an attribute value. Then whenever that attribute changes value, the client is notified.

            To do this requires a few steps.

            - Open two powershell terminals
            - In each establish a connection using Connect-MetasysAccount
            - In the first terminal, run Invoke-MetasysGetStream. In a short time you'll receive a hello event. The data in that event will be your stream id that you use to sign up for events.
            - In the second terminal, invoke an operation that supports subscriptions. For example, read the present value of an analog object and include the METASYS-SUBSCRIBE header with the value of your stream id. In the first terminal you should receive an object.values.update event with the current value of the object.
            - In the UI or in the second terminal, change the value of the attribute you read in the previous step. Within a short period of time you should see another object.values.update event with the new value.
    #>
    param (
        # By default the event stream is just a stream of text. Use this switch to stream a collection of objects instead
        [switch]$ReturnObjects
    )

    $token = [MetasysEnvVars]::getTokenAsPlainText()

    if ($null -eq $token ) {
        Write-Error "No connection to a Metasys site exists. Please connect using Connect-MetasysAccount"
        exit
    }

    $metasysHost = [MetasysEnvVars]::getSiteHost()
    $version = [MetasysEnvVars]::getVersion()
    $Url = "https://$metasysHost/api/v$version/stream"

    $request = [System.Net.WebRequest]::CreateHttp($Url)
    $request.Headers.Add("Authorization", "Bearer $token")
    $request.AllowReadStreamBuffering = $false
    $response = $request.GetResponse()
    $stream = $response.GetResponseStream()

    $encoding = [System.Text.Encoding]::UTF8

    if ($ReturnObjects) {
        $parser = New-EventParser
    }
    while ($true) {

        [byte[]]$buffer = New-Object byte[] 2048

        $length = $Stream.Read($buffer, 0, 2048)


        $text = $encoding.GetString($buffer, 0, $length)
        # We want to remove any trailing new line since the outputing of
        # $test is going to cause another new line to be sent anyway and
        # we want to avoid duplicated newlines

        if ($text.EndsWith("`r`n")) {
            $text = $text.Substring(0, $text.Length - 2)
        }
        elseif ($text.EndsWith("`n")) {
            $text = $text.Substring(0, $text.Length - 1)
        }

        if ($ReturnObjects) {
            # Split the text into lines and feed each to our event
            # parser
            $text -split '\r?\n' | ForEach-Object { &$parser -line $_ }
        } else {
            $text
        }

    }

}


Set-Alias -Name ims -Value Invoke-MetasysGetStream
Export-ModuleMember -Alias "ims"
Export-ModuleMember -Function "Invoke-MetasysGetStream"
