# Purpose of this module is to parse the event stream from the server
# line by line and generate Event objects

# Algorithm: https://html.spec.whatwg.org/multipage/server-sent-events.html#dispatchMessage



function New-EventParser {


    # Locals
    $script:data = ""
    $script:eventType = ""
    $script:lastEventId = ""

    #Return the following script block

    {
        param(
            [string]$line
        )

        if ($line.Length -eq 0) {
            # Dispatch the Event
            [PSCustomObject]@{
                EventType = $script:eventType;
                EventId   = $script:lastEventId;
                Data      = $script:data.ToString() | ConvertFrom-Json;
            }
            $script:data = ""
            $script:eventType = ""
        }
        elseif ($line.StartsWith(":")) {
            # Ignore
        }
        else {

            if ($line.IndexOf(":") -gt 0) {
                $pieces = $line -split ":", 2
                $fieldName = $pieces[0]
                $value = $pieces[1]
                if ($value.StartsWith(" ")) {
                    $value = $value.Substring(1)
                }
            }
            else {
                $fieldName = $line
                $value = ""
            }

            if ($FieldName -eq "event") {
                $script:eventType = $Value
            }

            if ($FieldName -eq "data") {
                $script:data = $Value
            }

            if ($FieldName -eq "id") {
                if (!$FieldName.Contains("\0")) {
                    $script:lastEventId = $Value
                }
            }

        }

    }.GetNewClosure()

}
