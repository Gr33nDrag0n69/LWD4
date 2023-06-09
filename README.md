# LWD4 - LiskWatchDog4

## Multi-OS Support

The code can run anywhere PowerShell 7 can run.

* Windows
* Linux
* MacOS

## Install/Configure Pre-Requisites on MGMT Client

"MGMT Client" is the computer where this tool will be executed.

* [Windows](./MD/Install-MGMT-Windows.md)
* [Linux](./MD/Install-MGMT-Linux.md)

## Install/Configure Pre-Requisites on Private Lisk-Core Node(s)

* [Linux](./MD/Install-Lisk-Core-Linux.md)

## Install Code on MGMT Client

You have multiple choices :

1. Download GitHub [Archive](https://github.com/Gr33nDrag0n69/LWD4/archive/refs/heads/main.zip)
2. Git Clone LWD4 to MGMT Client. Example: `git clone https://github.com/Gr33nDrag0n69/LWD4.git`
3. Git Fork LWD4 & do whatever you want.

## Edit LWD4 Config

I provided a sample config file in the `JSON` directory. BEFORE using the scripts, you must modify it to fit your configuration.

For the Betanet environment, please edit the configuration file titled `lwd4-config.beta.json`. Upon opening the file, you'll notice that the structure of each section is relatively easy to understand.

You're **required** to modify the following sections:

* Account
* Validator
* PrivateCoreNode

In addition to these, while it's not mandatory, I strongly suggest reviewing and validating the entries of the following sections to ensure optimal operation:

* DefaultCoreAPI
* DefaultServiceAPI
* PublicCoreNode
* PublicServiceNode

## Run Script(s)

* [Show-Dashboard](./MD/Show-Dashboard.md)
* [Show-GeneratorLastBlock](./MD/Show-GeneratorLastBlock.md)
* [Show-LiskServiceStatus](./MD/Show-LiskServiceStatus.md)

## SoonTM Note(s)

* Support testnet & mainnet lisk-core v4.
* Support multi tokenID. (I.e. Colecti, etc.)
* Support HTTPS "secure only" commands.
  * Create Documentation on how to add support for HTTPS "secure only" commands. on Private Lisk-Core Node(s)

## Special Note(s)

* Thanks to **przemer** for is answers to many current & future questions. :)
