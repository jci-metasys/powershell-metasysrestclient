

function find-internet-user {
    param (
        [string]$siteHost
    )

    if (!$IsMacOS) {
        return
    }

    $cred = Invoke-Expression "security find-internet-password -s $siteHost 2>/dev/null"
    if ($cred) {
        $userNameLine = $cred | Where-Object { $_.StartsWith("    ""acct") }
        if ($userNameLine) {
            $userName = $userNameLine.Split('=')[1].Trim('"')
            return $userName
        }
    }
}

function find-internet-password {
    param (
        [string]$siteHost,
        [string]$userName
    )

    if (!$IsMacOS) {
        return
    }

    $passwordEntry = Invoke-Expression "security find-internet-password -s $siteHost -a $userName -w 2>/dev/null"
    if ($passwordEntry) {
        return ConvertTo-SecureString $passwordEntry -AsPlainText
    }
}

function clear-internet-password {
    param(
        [String]$siteHost
    )

    if (!$IsMacOS) {
        return
    }

    Invoke-Expression "security delete-internet-password -s $siteHost 1>/dev/null"
}
function add-internet-password {
    param(
        [string]$siteHost,
        [string]$userName,
        [SecureString]$password
    )

    if (!$IsMacOS) {
        return
    }

    $plainText = ConvertFrom-SecureString -SecureString $password -AsPlainText

    Invoke-Expression "security add-internet-password -U -s $siteHost -a $userName -w $plainText -c mgw1  "

}
