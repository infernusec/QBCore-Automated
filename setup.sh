
# Bash Colours
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

UNIX_USER="qbcfivem"
DB_USER="fivem"

echo -e "${Cyan}[INFO]:${White} QBCore Automated Installer"
echo -e "${Cyan}[INFO]:${White} Removing old packages & files & users.."



remove_install() {
    rm -rf /usr/lib/systemd/system/qbcore.service
    userdel $UNIX_USER 1>/dev/null
    rm -rf /home/$UNIX_USER/
    systemctl stop qbcore mariadb 1>/dev/null
    systemctl disable qbcore mariadb 1>/dev/null
    dnf remove -y mariadb 1>/dev/null
    rm -rf /etc/yum.repos.d/mariadb.repo
}

random_password() {
    head -1 /dev/random | md5sum | awk '{ print $1;}'
}

update_repos(){
    echo -e "${Cyan}[INFO]:${White} Updating repo list.."
    dnf update -y 1>/dev/null; dnf makecache -y 1>/dev/null
}

# Generate Auto passwords
echo -e "${Cyan}[INFO]:${White} Generating Passwords for DB User and Unix user.."
DB_PASS=$(random_password)
UNIX_USER_PASS=$(random_password)
MARIADB_RELEASEVER="10.11"

update_repos
echo -e "${Cyan}[INFO]:${White} Installing basic Packages.."
dnf install -y epel-release 1>/dev/null
dnf install -y nano git zip unzip firewalld tar xz 1>/dev/null
update_repos
echo -e "${Cyan}[INFO]:${White} Adding user [$UNIX_USER].."
adduser "$UNIX_USER" 1>/dev/null
echo -e "$UNIX_USER_PASS\n$UNIX_USER_PASS" | passwd "$UNIX_USER" 1>/dev/null

# Add user to sudo group
usermod -a -G wheel $UNIX_USER 1>/dev/null

echo -e "${Cyan}[INFO]:${White} Prepare server files.."
mkdir -p "/home/$UNIX_USER/server"
cd "/home/$UNIX_USER/server"

LATEST_QBCORE=$(curl -s https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | grep 'panel-block  is-active' | head -1 | cut -d '"' -f 4 | cut -c3- | awk '{ print "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"$1; }')
QBCORE_RELEASEVER=$(echo $LATEST_QBCORE | sed "s|https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/||g" | cut -d '-' -f1)
echo -e "${Cyan}[INFO]:${White} QBcore latest release is: $QBCORE_RELEASEVER.."
echo -e "${Cyan}[INFO]:${White} Downloading & Extracting files to \"/home/$UNIX_USER/server..\""
wget -qO- $LATEST_QBCORE | tar --xz -x
chown -R $UNIX_USER:$UNIX_USER "/home/$UNIX_USER/server"
echo -e "# MariaDB $MARIADB_RELEASEVER RedHatEnterpriseLinux repository list
# https://mariadb.org/download/
[mariadb]
name = MariaDB
# rpm.mariadb.org is a dynamic mirror if your preferred mirror goes offline. See https://mariadb.org/mirrorbits/ for details.
# baseurl = https://rpm.mariadb.org/$MARIADB_RELEASEVER/rhel/\$releasever/\$basearch
baseurl = https://ftp.agdsn.de/pub/mirrors/mariadb/yum/$MARIADB_RELEASEVER/rhel/\$releasever/\$basearch
# gpgkey = https://rpm.mariadb.org/RPM-GPG-KEY-MariaDB
gpgkey = https://ftp.agdsn.de/pub/mirrors/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck = 1" > /etc/yum.repos.d/mariadb.repo
update_repos

echo -e "${Cyan}[INFO]:${White} Installing MariaDB $MARIADB_RELEASEVER.."
dnf install -y expect mariadb-server 1>/dev/null
systemctl enable --now mariadb 1>/dev/null
SECURE_MYSQL=$(expect -c '
set timeout 10
spawn mariadb-secure-installation
expect "Enter current password for root (enter for none):"
send "\r"
expect "Switch to unix_socket authentication"
send "n\r"
expect "Change the root password?"
send "n\r"
expect "Remove anonymous users?"
send "y\r"
expect "Disallow root login remotely?"
send "y\r"
expect "Remove test database and access to it?"
send "y\r"
expect "Reload privilege tables now?"
send "y\r"
expect eof')
echo "$SECURE_MYSQL"
dnf remove -y expect 1>/dev/null
systemctl restart mariadb 1>/dev/null

echo -e "${Cyan}[INFO]:${White} Creating QBCore DB User [$DB_USER].."
mysql -uroot -e "CREATE USER '$DB_USER'@localhost IDENTIFIED BY '$DB_PASS';"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@localhost IDENTIFIED BY '$DB_PASS';"
mysql -uroot -e "FLUSH PRIVILEGES;"


# create a service for qbcore to get an ability to rehalth..
echo -e "${Cyan}[INFO]:${White} Generating systemd qbcore service.."
echo "[Unit]
Description=Fivem QBCore Framework v6457 server
Documentation=https://docs.qbcore.org/qbcore-documentation/guides/linux-installation
After=network.target

[Install]
WantedBy=multi-user.target


[Service]
Type=simple
User=$UNIX_USER
Group=$UNIX_USER
ExecStart=/home/$UNIX_USER/server/run.sh
KillSignal=SIGTERM
SendSIGKILL=no
Restart=on-abort
RestartSec=5s
PrivateTmp=true
LimitNOFILE=32768" > /usr/lib/systemd/system/qbcore.service

systemctl daemon-reload 1>/dev/null
systemctl enable --now qbcore 1>/dev/null
echo -e "${Green}[NOTICE]:${White} Starting QBCore service.."
echo -e "${Green}[INFO]:${White} Waiting for QBCore.."
sleep 2
JOURNALCTL_QBCORE=$(journalctl -u qbcore.service)
txAdminToken=$(echo -e "$JOURNALCTL_QBCORE" | grep 'master' | tail -1 | rev | awk '{ print $1;}' | rev)
txAdminUI=$(echo -e "$JOURNALCTL_QBCORE" | grep '┃' | grep 'http' | tail -1 | cut -d '┃' -f2 | awk '{ print $1; }')
txAdminPort=$(echo -e "$txAdminUI" |  cut -d ':' -f3 | sed 's/\///g')
txAdminIP=$(echo $txAdminUI | sed "s|http://||g;s|https://||g;s|/||g;" | cut -d ':' -f1)

echo -e "${Green}[INFO]:${White} Enable Firewall & Applying firewall rules.."
QBC_SERVER_PORT=$(cat /home/$UNIX_USER/server/alpine/opt/cfx-server/citizen/system_resources/monitor/docs/dev_notes.md | grep 'fxServerPort' | awk '{ print $2; }' | sed 's|,||g')
systemctl enable --now firewalld 1>/dev/null
firewall-cmd --zone=public --add-port="$txAdminPort/tcp" --permanent 1>/dev/null
firewall-cmd --zone=public --add-port="$QBC_SERVER_PORT/tcp" --permanent 1>/dev/null
firewall-cmd --zone=public --add-port="$QBC_SERVER_PORT/udp" --permanent 1>/dev/null
firewall-cmd --zone=public --remove-service="cockpit" --permanent 1>/dev/null
firewall-cmd --reload 1>/dev/null

# Secure OpenSSH
echo -e "${Green}[INFO]:${White} Securing OpenSSH Server.."
sed -i "s|PermitRootLogin yes|PermitRootLogin no|g" /etc/ssh/sshd_config
systemctl restart sshd 1>/dev/null

echo -e "${White}= = = = = = [ ${Green}Installation Completed${White} ] = = = = = ="
echo -e "${Yellow}DB User: ${White}$DB_USER"
echo -e "${Yellow}DB Pass: ${White}$DB_PASS"
echo -e "${Yellow}Unix User: ${White}$UNIX_USER"
echo -e "${Yellow}Unix Pass: ${White}$UNIX_USER_PASS"
echo -e "${Yellow}txAdmin Url: ${White}$txAdminUI"
echo -e "${Yellow}txAdmin Token: ${White}$txAdminToken"
echo -e "${Yellow}txAdmin & Server IP: ${White}$txAdminIP"
echo -e "${Yellow}Server Port (TCP/UDP): ${White}$QBC_SERVER_PORT"
echo -e "${Green} Save those details in a secret place!${Color_Off}"
echo -e "${White}= = = = = = [ ${Red} I M P O R T A N T   T O   R E A D  ! ! ! ${White} ] = = = = = ="
echo -e "${Red} For security reasons, You are not be able to connect as ${White}root${Red} user anymore!"
echo -e "${Red} at the next time you need to login as user ${White}$UNIX_USER${Red}"
echo -e "${Cyan} To shutdown/restart your server, use systemd command, for Example: ${White}systemctl ${Green}start${White} qbcore.service${Red}"
echo -e "${Cyan} The available options are: ${White}start/stop/enable/disable\n${Cyan}enable/disable - means that the service qbcore will automaticlly start when the is server power on."
