# Install-MGMT-Linux

## Install PowerShell 7

Microsoft Doc: [Installing PowerShell on Linux](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.3)

If you are unsure of the method to use, you probably want to [Install on Ubuntu via Package Repository](https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.3#installation-via-package-repository).

```sh
# Existing Packages
# Ubuntu 22.04 - https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
# Ubuntu 20.04 - https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
# Ubuntu 18.04 - https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb

# Update the list of packages
sudo apt-get update

# Install pre-requisite packages.
sudo apt-get install -y wget apt-transport-https software-properties-common

# Download the Microsoft repository GPG keys
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"

# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb

# Delete the the Microsoft repository GPG keys file
rm packages-microsoft-prod.deb

# Update the list of packages after we added packages.microsoft.com
sudo apt-get update

# Install PowerShell
sudo apt-get install -y powershell
```

## Linux PowerShell 7 Note

There is 2 ways of using `pwsh` on linux.

* Switching to a full PS7 shell with the `pwsh` command.
  * Execute command(s) like in Windows. I.e.: `.\Script.ps1`
* Executing script directly from bash: `pwsh .\Script.ps1`
