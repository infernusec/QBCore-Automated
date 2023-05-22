
# QBCore Automated Installer
a fivem QBCore framework automated installation script
This script works on rocky linux 9/RHEL9..

This script installs a QBCore fivem latest framework with a good security practices and latest packages..
Whats is installs?
- MariaDB 10.11.X - for qbcore database contents..
- FirewallD - a firewall to open a specific ports and close anything else..
- Non-Root process - if someones hacks to ypur server, he can't get an access to root user, because the proccess isn't runs as root user.

## How to install?

```
cd ~/
wget https://raw.githubusercontent.com/infernusec/QBCore-Automated/main/setup.sh
chmod +x setup.sh
./setup.sh
```
## Commands
| Command | Description |
|--|--|
| systemctl [start/stop/status/enable/disable] qbcore | start/stop,etc.. QBCore server |
| journalctl -u qbcore.service | Get latest logs from qbcore service |
