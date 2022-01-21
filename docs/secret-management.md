# Secret Management

The `Microsoft.PowerShell.SecretManagement` module is a cross platform solution
for managing secrets (like passwords, for example). If it has been installed and
configured with a Secret Vault then `Connect-MetasysAccount` will save
credentials to the vault. On your next session you won't need to supply a
`UserName` or `Password`. (A `UserName` is required if you are using multiple
accounts for the same host).

The SecretManagement module relies on one or more Secret Vaults being installed
and registered. (See
[SecretManagement and SecretStore Are Generally Available](https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/)
for more details). There are several options of vaults available:

- Microsoft.PowerShell.SecretStore
- SecretManagement.JustinGrote.CredMan (uses windows credential manager as
  backing store)
- SecretManagement.KeyChain (uses macOS Keychain as backing store)
- SecretManagement.KeePass (uses KeePass as a backing store)
- SecretManagement.LastPass (uses LastPass as a backing store)
- SecretManagement.1Password (uses 1Password as a backing store)

If you don't know which one to pick it is recommended that you use the
Microsoft.PowerShell.SecretStore implementation. If you choose a different one,
please see the documentation on how to configure it.

There are three steps to follow

- Installation
- Configuration
- Registration

## Installation

Install the two modules

```powershell
PS > Install-Module Microsoft.PowerShell.SecretStore -Repository PSGallery
PS > Install-Module Microsoft.PowerShell.SecretManagement -Repository PSGallery
```

## Configuration

Now you need to configure and register the SecretStore vault. You need to decide
if you will require a password to unlock your vault.

### No Authentication

If you are using this only in a test environment with fake/test accounts you may
not feel the need to password protect your vault. In that case you can use the
following command to configure SecretStore. _Use at your own risk._

```powershell
PS > Set-SecretStoreConfiguration -Authentication None -Interaction None
```

### Authentication with Password

If your vault will store sensitive passwords you'll want to set a password for
the vault. Set the timeout (in seconds) to a value you are comfortable with.

```powershell
PS > Set-SecretStoreConfiguration -Authentication Password -PasswordTimeout 1800 -Interaction None
```

This configuration will never prompt you for a password. So when using
`Connect-MetasysAccount` you'll get an error if the vault is not unlocked. You
can change the value of `Interaction` to `Prompt` if you wish to be prompted.

To unlock the secret store

```powershell
PS > Unlock-SecretStore

cmdlet Unlock-SecretStore at command pipeline position 1
Supply values for the following parameters:
Password: ********
```

## Registration

Now you need to register the SecretStore with the SecretManagement module:

```powershell
PS > Register-SecretVault -Name SecretStore -Module Microsoft.PowerShell.SecretStore
```

## Test

To test your installation is working correctly try to add a new secret

```powershell
# Create a secret
PS > Set-Secret -Name test-secret -Secret thisIsASecret

# Retrieve a secret (returned as SecureString by default)
PS > Get-Secret -Name test-secret
System.Security.SecureString

# Retrieve a secret as plain text
PS > Get-Secret -Name test-secret -AsPlainText
thisIsASecret

# Delete a secret, Vault name is required
PS > Remove-Secret -Name test-secret -Vault SecretStore
```

If there were no errors you are all set. The `MetasysRestClient` module will now
use the default secret vault to save any passwords.

## Managing Passwords

What happens if your password is saved in your secret vault but you recently
changed it to a new value. The next time you use `Connect-MetasysAccount` to
start a session it'll use the wrong password. To discover and delete the
passwords saved in the secret vault you can use the commands exposed by
`SecretManagement`. Alternatively you can use some convenience commands that
come as part of `MetasysRestClient` that makes it easier to find those passwords
stored by this module.

### List Secrets Using Built-In Commands

In this first example we'll use `Get-SecretInfo` which is a function defined by
the SecretManagement module:

```powershell
PS > Get-SecretInfo

Name                  Type         VaultName
----                  ----         ---------
imm:192.168.1.128:api SecureString SecretStore
imm:testoas:api       SecureString SecretStore
imm:welchoas:api      SecureString SecretStore
```

All of the secrets saved by `Invoke-MetasysMethod` are prefixed with `imm`, and
the `Name` of each secret is a combination of the `MetasysHost` and `UserName`.

### Listing Saved Users

It's a little more user friendly to use `Get-SavedMetasysUsers` which will
display all the UserNames that have been saved by this module.

```powershell
PS > Get-SavedMetasysUsers
Host             UserName
-----------      --------
192.168.1.128    api
testoas          api
welchoas         api
```

In this example you can see I have saved credentials for a user named `api` on
three different hosts.

### Reading A Password

Perhaps you want to see what the saved password is. You can use
`Get-SavedMetasysPassword`.

> **NOTE** This command does not and cannot read passwords from a Metasys site.
> It only retrieves any credentials you have saved locally in your secret vault.

To look up a password, provide the `UserName` and `MetasysHost`:

```powershell.
PS > Get-SavedMetasysPassword -UserName api -MetasysHost welchoas
System.Security.SecureString
```

Notice, by default, the password will not display on the console. It is stored
securely in a `SecureString`. If you need to see it you can convert it to plain
text using `ConvertFrom-SecureString` or pass the `AsPlainText` switch to
`Get-SavedMetasysPassword`:

```powershell
PS > Get-SavedMetasysPassword -UserName api -MetasysHost welchoas -AsPlainText
mysupersecretpassword
```

### Deleting Credentials

Finally let's say you need to delete a set of credentials because the password
is incorrect. For this use `Remove-SavedMetasysPassword`.

> **NOTE** This command does not and cannot delete credentials from a Metasys
> site. It only removes any credentials you have saved locally in your secret
> vault.

```powershell
PS > Remove-SavedMetasysPassword -UserName api -MetasysHost welchoas
Supply values for the following parameters:
Vault: SecretStore
```

Notice that it prompted me for the name of my Vault. When we registered our
vault we named it `SecretStore`. If you named it something else you'd supply
that value now. This is an important feature as it ensures that if you have
multiple vaults you don't accidentally delete the wrong credential from the
wrong vault. If you have multiple vaults registered you'll want to know all of
their names.

### Changing a Saved Password

Rather than deleting a saved set of credentials you could instead just change
the saved password using `Set-SavedMetasysPassword`:

```powershell
PS > Set-SavedMetasysPassword -UserName api -MetasysHost welchoas
Supply values for the following parameters:
Password: *********
```

> **NOTE** This command does not and cannot save credentials on a Metasys site.
> It only saves credentials locally in your secret vault.
