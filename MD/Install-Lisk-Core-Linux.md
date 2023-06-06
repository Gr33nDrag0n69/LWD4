# Install-Lisk-Core-Linux

## Uncomplicated Firewall (UFW)

Please note: To avoid getting disconnected from your server, ensure that your management IP remains static while utilizing the 'Allow From' command. In case of any uncertainty, refrain from using 'Allow From'. Instead, just open port 22 (SSH) using `sudo ufw allow '22/tcp'`.

The default HTTP API port for the Lisk-Core betanet is `7887`.

However, it's not advisable to make this port publicly accessible, yet you would still want to activate it on 0.0.0.0 (as opposed to 127.0.0.1) and access it from the management client.

The most efficient way to accomplish this is by whitelisting the public IP address of the management client on each private node.

```shell
sudo ufw allow from "100.150.200.250/32"
```


## Configuring Lisk-Core

The LWD4 code communicates with the HTTP API endpoint of Lisk-Core, which is disabled by default.

The standard configuration of Lisk-Core sets the RPC to listen only to localhost requests, which requires modification.

You are required to edit the default config.json (or your custom-config) to implement these changes.

**Reminder: After editing the configuration file, make sure to stop and then restart the node to apply the new configuration file before proceeding with the following steps!**

```txt
vi ~/.lisk/lisk-core/config/config.json

# Replace this:
  "rpc": {
    "modes": [
      "ipc",
      "ws"
    ],
    "port": 7887,
    "host": "127.0.0.1",
    "disabledMethods": []
  },

# By this
  "rpc": {
    "modes": [
      "ipc",
      "ws",
      "http"
    ],
    "port": 7887,
    "host": "0.0.0.0",
    "disabledMethods": []
  },
```

