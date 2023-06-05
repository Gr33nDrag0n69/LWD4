# Install-MGMT-Linux

## Install PowerShell 7

Microsoft Doc: [Installing PowerShell on Linux](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.3)

The following shell code is for Ubuntu 18.04, 20.04 & 22.04 ONLY, for anything else refers to Microsoft documentation.

```shell
# Install Required Packages
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common

# Download & Register the Microsoft repository GPG keys
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install PowerShell
sudo apt-get update
sudo apt-get install -y powershell
```

## Linux PowerShell 7 Note

There is 2 ways of using `pwsh` on linux.

1. You can switch to a full PS7 shell with the `pwsh` command.
  * Execute command(s) like in Windows.
  * Use command `exit` to go back to linux shell.

2. You can also execute PS7 script directly from bash: `pwsh .\Script.ps1`

Bottom line it's the same output, I would say the choice is only a question of preferences & also if you intend to run a single PS7 command or multiple PS7 commands.

Here an example of both:
```shell
# PS7 Shell
username@hostname:~/LWD4$ pwsh
PowerShell 7.3.4
PS /home/username/LWD4> ./Show-Dashboard.ps1 -Net Beta

# As Bash CMD
username@hostname:~/LWD4$ pwsh ./Show-Dashboard.ps1 -Net Beta
```

