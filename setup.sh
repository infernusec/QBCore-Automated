# A Secure installation for QBCore Framework, runs on Non-Root user. (which provides a better security)
# This scripts are installs the server by using the BEST-PRACTICES
# The scripts installs also Nginx & phpMyAdmin which provides a better tools to manage the database.
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

UNIX_USER="qbcfivem"
DB_USER="fivem"

# DOMAINS for Control panels! [Change it!!]
PMA_EXT_DOMAIN="pma-fivem.snirsofer.com"
TXADMIN_EXT_DOMAIN="txadmin-fivem.snirsofer.com"
PLAY_UPSTREAM_EXT_DOMAIN="gta.snirsofer.com"



echo -e "${Cyan}[INFO]:${White} QBCore Automated Installer"
if [ -e "/usr/lib/systemd/system/qbcore.service" ]; then 
    echo -e "${Red}[ERROR]:${White} QBCore already installed! Exit..."
    exit 1
fi
echo -e "${Cyan}[INFO]:${White} Removing old packages & files & users.."
SELINUX_STATE=$(cat /etc/selinux/config | grep 'SELINUX=' | grep -v '#')
echo -e "${Cyan}[INFO]:${White} Disabling SELinux.."
setenforce 0
sed -i "s/$SELINUX_STATE/SELINUX=disabled/g" /etc/selinux/config


remove_install() {
    rm -rf /usr/lib/systemd/system/qbcore.service
    userdel $UNIX_USER 1>/dev/null
    rm -rf /home/$UNIX_USER/
    systemctl stop qbcore mariadb 1>/dev/null
    systemctl disable qbcore mariadb 1>/dev/null
    dnf remove -y mariadb php nginx 1>/dev/null
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
PMA_VERSION="5.2.1"

update_repos
echo -e "${Cyan}[INFO]:${White} Installing basic Packages.."
dnf install -y epel-release 1>/dev/null
dnf install -y nano git zip unzip firewalld tar xz 1>/dev/null
dnf install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm &>/dev/null
update_repos
dnf module enable php:remi-8.2 -y &>/dev/null
dnf install -y htop nginx php php-cli php-mbstring php-fpm php-gd php-mysqli php-zip php-sodium 1>/dev/null
mkdir -p /usr/share/nginx/pma
wget "https://files.phpmyadmin.net/phpMyAdmin/$PMA_VERSION/phpMyAdmin-$PMA_VERSION-all-languages.zip" -O /tmp/pma.zip &>/dev/null
unzip /tmp/pma.zip -d /usr/share/nginx/pma &>/dev/null
PMA_PATH="/usr/share/nginx/pma/phpMyAdmin-$PMA_VERSION-all-languages"
PMA_RAND_BLOWFISH=$(php -r 'echo bin2hex(random_bytes(32)) . PHP_EOL;')
PMA_RAND_BLOWFISH=$(echo "sodium_hex2bin('${PMA_RAND_BLOWFISH}')")
cp "${PMA_PATH}/config.sample.inc.php" "${PMA_PATH}/config.inc.php"
sed -i "s|cfg\['blowfish_secret'\] = '';|cfg\['blowfish_secret'\] = $PMA_RAND_BLOWFISH;|g" "${PMA_PATH}/config.inc.php"
chown -R apache:apache /usr/share/nginx/pma


echo -e "${Green}[INFO]:${White} Configure Nginx for phpMyAdmin & txAdmin.."
echo "server {
    listen       80;
    listen       [::]:80;
    server_name  $PMA_EXT_DOMAIN;
    root         $PMA_PATH;
    index index.php;
    gzip  on;
    gzip_comp_level 5;
    gzip_buffers 16 8k;
    gzip_disable \"MSIE [1-6]\.\";
    gzip_proxied any;
    gzip_types application/atom+xml application/javascript application/x-javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/xml+rss application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/xml text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/javascript text/x-component text/x-cross-domain-policy;
    
    location ~* \.(js|jpg|jpeg|gif|png|css|tgz|gz|rar|bz2|doc|pdf|ppt|tar|wav|bmp|rtf|swf|ico|flv|txt|woff|woff2|svg)$ {
        expires 30d;
        add_header Pragma "public";
        add_header Cache-Control "public";
    }
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_intercept_errors on;
        fastcgi_index  index.php;
        include        fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        fastcgi_pass   php-fpm;
    }
}" > /etc/nginx/conf.d/pma.conf

echo "server {
    listen       80;
    listen       [::]:80;
    server_name  $TXADMIN_EXT_DOMAIN;
    gzip  on;
    gzip_comp_level 2;
    gzip_buffers 16 8k;
    gzip_disable \"MSIE [1-6]\.\";
    gzip_proxied any;
    gzip_types application/atom+xml application/javascript application/x-javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/xml+rss application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/xml text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/javascript text/x-component text/x-cross-domain-policy;
    location / {
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header Host \$host;
            proxy_pass http://127.0.0.1:40120;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
    }
}" > /etc/nginx/conf.d/txadmin.conf


#echo "stream {
#    upstream backend {
#        server 100.64.1.2:30120;
#    }
#    server { listen 30120; proxy_pass backend; }
#    server { listen 30120 udp reuseport; proxy_pass backend; }
#}" >  /usr/share/nginx/modules/fivem_upstream.conf

# Create an ramdisk mount as filesystem
NGX_UPSTREAM_RAMDISK_SIZE="1g"

echo "upstream fivem {
    server 127.0.0.1:30120;
}
proxy_cache_path /home/$UNIX_USER/ram/upstream_cache levels=1:2 keys_zone=fivem_assets:48m max_size=${NGX_UPSTREAM_RAMDISK_SIZE} inactive=2h;
server {
    listen       80;
    listen       [::]:80;
    server_name  $PLAY_UPSTREAM_EXT_DOMAIN;
    gzip  on;
    gzip_comp_level 2;
    gzip_buffers 16 8k;
    gzip_disable \"MSIE [1-6]\.\";
    gzip_proxied any;
    gzip_types application/atom+xml application/javascript application/x-javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/xml+rss application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/xml text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/javascript text/x-component text/x-cross-domain-policy;

    location / {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        # required to pass auth headers correctly
        proxy_pass_request_headers on;
        # required to not make deferrals close the connection instantly
        proxy_http_version 1.1;
        proxy_pass http://fivem;
    }

    # extra block for a caching proxy
    location /files/ {
        proxy_pass http://fivem\$request_uri;
        add_header X-Cache-Status \$upstream_cache_status;
        proxy_cache_lock on;
        proxy_cache fivem_assets;
        proxy_cache_valid 1y;
        proxy_cache_key \$request_uri\$is_args$args;
        proxy_cache_revalidate on;
        proxy_cache_min_uses 1;
    }
}" > /etc/nginx/conf.d/play.conf


# Delete nginx.conf default virtualhost..
NGINX_DELETE_FROM_LINE=$(cat /etc/nginx/nginx.conf | grep -n 'include /etc/nginx/conf.d/' | head -1 | cut -d ':' -f1)
NGINX_DELETE_FROM_LINE=$((NGINX_DELETE_FROM_LINE + 1))
sed -i "${NGINX_DELETE_FROM_LINE},\$d" /etc/nginx/nginx.conf
echo "}" >> /etc/nginx/nginx.conf



echo -e "${Cyan}[INFO]:${White} Improve kernel values.."
echo "# Decrease Swappiness: Reducing the kernel's tendency to swap can improve system performance by keeping more data in the physical memory:
vm.swappiness = 10

# Increase File-Max: This is the maximum file handles that the kernel will allocate. If you are running a system that opens many files, you might need to increase this:
fs.file-max = 2097152

# Optimize Network Performance: These settings help to optimize TCP/IP stack for better network throughput:
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216

# Increase the size of the IPC resources: This is useful in database servers where the application requires high IPC resources:
kernel.shmmax = 4294967296
kernel.shmall = 4194304

kernel.msgmnb = 65536
kernel.msgmax = 65536

# Adjusting Writeback Cache:
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# Avoiding Ping requests
net.ipv4.icmp_echo_ignore_all=1

# These settings can improve security by controlling how the system handles various network scenarios
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.tcp_syncookies = 1

# Handling of Memory Shortages: Adjusts how the kernel reacts to a shortage of memory:
vm.overcommit_memory = 1

# Adjust System Request Timeout: This value is measured in seconds:
kernel.sysrq = 1

# Increase the Number of PIDs: This could help if you're running a large number of processes:
kernel.pid_max = 4194303

# Avoiding "Out of Memory" Situations:
vm.min_free_kbytes = 65536" > /etc/sysctl.d/10-fivem.conf

echo -e "${Cyan}[INFO]:${White} Adding user [$UNIX_USER].."
adduser "$UNIX_USER" 1>/dev/null
echo -e "$UNIX_USER_PASS\n$UNIX_USER_PASS" | passwd "$UNIX_USER" &>/dev/null

# Add user to sudo group
# usermod -a -G wheel $UNIX_USER 1>/dev/null

# new strict, allow to user run only systemctl command for specific service (such a qbcore)
sed -i "/^# %wheel\s\+ALL=(ALL)\s\+NOPASSWD: ALL$/a $UNIX_USER ALL=(ALL) NOPASSWD: /bin/systemctl status qbcore, /bin/systemctl start qbcore, /bin/systemctl stop qbcore, /bin/systemctl restart qbcore, /bin/systemctl enable qbcore, /bin/systemctl disable qbcore, /bin/journalctl -u qbcore.service" /etc/sudoers


echo -e "${Cyan}[INFO]:${White} Prepare server files.."
mkdir -p "/home/$UNIX_USER/server"
mkdir -p "/home/$UNIX_USER/ram/upstream_cache"
cd "/home/$UNIX_USER/server"

# create ramdisk nginx
echo "tmpfs       /home/$UNIX_USER/ram/upstream_cache   tmpfs   size=${NGX_UPSTREAM_RAMDISK_SIZE},mode=0777   0 0" >> /etc/fstab
systemctl daemon-reload
mount /home/$UNIX_USER/ram/upstream_cache


LATEST_QBCORE=$(curl -s https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | grep 'panel-block  is-active' | head -1 | cut -d '"' -f 4 | cut -c3- | awk '{ print "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"$1; }')
QBCORE_RELEASEVER=$(echo $LATEST_QBCORE | sed "s|https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/||g" | cut -d '-' -f1)
echo -e "${Cyan}[INFO]:${White} QBcore latest release is: $QBCORE_RELEASEVER.."
echo -e "${Cyan}[INFO]:${White} Downloading & Extracting files to \"/home/$UNIX_USER/server..\""
wget -qO- $LATEST_QBCORE | tar --xz -x
chown -R $UNIX_USER:$UNIX_USER "/home/$UNIX_USER/server"

# Remove Ads from txAdmin..
echo -e "${Green}[INFO]:${White} Removing Ads from txAdmin source files.."
grep -iRl '(dynamicAd)' alpine/opt/ | while read -r line; do sed -i "s|(dynamicAd)|(1 > 2)|g" $line; done
LINE_DISCORD_TXADMIN=$(grep -n -B 1 "Discord" alpine/opt/cfx-server/citizen/system_resources/monitor/web/standalone/login.ejs | head -1 | awk '{ print $1; }' | sed 's/-//g')
sed -i "${LINE_DISCORD_TXADMIN}s/text-muted/d-none/" alpine/opt/cfx-server/citizen/system_resources/monitor/web/standalone/login.ejs

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
dnf install -y expect mariadb-server &>/dev/null
systemctl enable --now mariadb &>/dev/null
echo -e "${Cyan}[INFO]:${White} Running MariaDB Secure Installation.."
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
CHECK_MARIADB_INSTALL=$(echo $SECURE_MYSQL | grep 'All done!')
if [ -z "$CHECK_MARIADB_INSTALL"  ]; then
    echo -e "${Cyan}[INFO]:${White} MariaDB was set up successfully!"
else
    echo -e "${Red}[ERROR]:${White} MariaDB Installation returns !"
    echo "$SECURE_MYSQL"
fi



dnf remove -y expect 1>/dev/null
systemctl restart mariadb 1>/dev/null

echo -e "${Cyan}[INFO]:${White} Creating QBCore DB User [$DB_USER].."
mysql -uroot -e "CREATE USER '$DB_USER'@localhost IDENTIFIED BY '$DB_PASS';"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@localhost IDENTIFIED BY '$DB_PASS';"
#mysql -uroot -e "GRANT SELECT, INSERT, DELETE, UPDATE, CREATE, DROP, INDEX, ALTER LOCK TABLES ON *.* TO '$DB_USER'@localhost IDENTIFIED BY '$DB_PASS';"
mysql -uroot -e "FLUSH PRIVILEGES;"




# Replace source files database login data..
sed -i "s|mysqlUser:\"root\",mysqlPort:\"3306\",mysqlPassword:\"\"|mysqlUser:\"$DB_USER\",mysqlPort:\"3306\",mysqlPassword:\"$DB_PASS\"|g" /home/$UNIX_USER/server/alpine/opt/cfx-server/citizen/system_resources/monitor/core/index.js
sed -i "s|mysqlUser\|\|\"root\"|mysqlUser\|\|\"$DB_USER\"|g" /home/$UNIX_USER/server/alpine/opt/cfx-server/citizen/system_resources/monitor/core/index.js
sed -i "s|mysqlPassword\|\|\"\"|mysqlPassword\|\|\"$DB_PASS\"|g" /home/$UNIX_USER/server/alpine/opt/cfx-server/citizen/system_resources/monitor/core/index.js


# create a service for qbcore to get an ability to rehalth..
echo -e "${Cyan}[INFO]:${White} Generating systemd qbcore service.."
echo "[Unit]
Description=Fivem QBCore Framework v${QBCORE_RELEASEVER} server
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
LimitNOFILE=100000
LimitMEMLOCK=infinity
LimitCPU=infinity" > /usr/lib/systemd/system/qbcore.service

systemctl daemon-reload 1>/dev/null
systemctl enable --now qbcore &>/dev/null
systemctl enable --now php-fpm &>/dev/null
systemctl enable --now nginx &>/dev/null
echo -e "${Green}[NOTICE]:${White} Starting QBCore service.."
echo -e "${Green}[INFO]:${White} Waiting for qbcore.service to fetch setup items.."
sleep 10
txAdminToken=$(journalctl -u qbcore.service | grep '    ┃' | tail -2 | head -1 | rev | awk '{ print $2 }' | rev)
txAdminUI=$(journalctl -u qbcore.service | grep '┃' | grep 'http' | tail -1 | cut -d '┃' -f2 | awk '{ print $1; }')
txAdminPort=$(echo -e "$txAdminUI" |  cut -d ':' -f3 | sed 's/\///g')
txAdminIP=$(echo $txAdminUI | sed "s|http://||g;s|https://||g;s|/||g;" | cut -d ':' -f1)

echo -e "${Green}[INFO]:${White} Enable Firewall & Applying firewall rules.."
QBC_SERVER_PORT=$(cat /home/$UNIX_USER/server/alpine/opt/cfx-server/citizen/system_resources/monitor/docs/dev_notes.md | grep 'fxServerPort' | awk '{ print $2; }' | sed 's|,||g')
systemctl enable --now firewalld 1>/dev/null




# Access from Nginx only!
# firewall-cmd --zone=public --add-port="$txAdminPort/tcp" --permanent 1>/dev/null

firewall-cmd --zone=public --add-service="http" --permanent 1>/dev/null
#firewall-cmd --zone=public --add-service="https" --permanent 1>/dev/null
firewall-cmd --zone=public --add-port="$QBC_SERVER_PORT/tcp" --permanent 1>/dev/null
firewall-cmd --zone=public --add-port="$QBC_SERVER_PORT/udp" --permanent 1>/dev/null
firewall-cmd --zone=public --remove-service="cockpit" --permanent 1>/dev/null
firewall-cmd --reload 1>/dev/null

# Secure OpenSSH
echo -e "${Green}[INFO]:${White} Securing OpenSSH Server.."
sed -i "s|PermitRootLogin yes|PermitRootLogin no|g" /etc/ssh/sshd_config
systemctl restart sshd 1>/dev/null

echo -e "${Green}[INFO]:${White} Return Selinux to its original state.."
sed -i "s|SELINUX=disabled|$SELINUX_STATE|g" /etc/selinux/config



find "/home/$UNIX_USER/server" -type f -name "server.cfg" | while read -r line; do
    echo "set sv_forceIndirectListing true" >> $line
    echo "set sv_listingHostOverride \"$PLAY_UPSTREAM_EXT_DOMAIN\"" >> $line
    echo "set sv_proxyIPRanges \"127.0.0.1/32\"" >> $line
    echo "set sv_endpoints \"127.0.0.1:30120\"" >> $line
    # obfuscates files with a global key, instead of a per-client key
    echo "set adhesive_cdnKey \"yourSecret\"" >> $line
    # adds a file server for 'all' resources
    echo "fileserver_add \".*\" \"http://$PLAY_UPSTREAM_EXT_DOMAIN/files\"" >> $line
done

# read -p "Configure Cloudflare Hostname? (y/n)" CONFIGURE_CF_HOSTNAME
# gta A 1.2.3.4 (with the proxy thing UNTICKED in CF)
# _cfx._udp SRV gta.yourdomain.com 382 30120

cd "/home/$UNIX_USER/"
DETAILS_FILE_NAME="qbcore-setup.txt"
echo -e "${White}= = = = = = [ ${Green}Installation Completed${White} ] = = = = = ="
echo -e "${Yellow}DB User: ${White}$DB_USER" | tee -a $DETAILS_FILE_NAME
echo -e "${Yellow}DB Pass: ${White}$DB_PASS" | tee -a $DETAILS_FILE_NAME
echo -e "${Yellow}phpMyAdmin Url: ${White}http(s)://$PMA_EXT_DOMAIN" | tee -a $DETAILS_FILE_NAME
echo -e "${Yellow}Unix User: ${White}$UNIX_USER" | tee -a $DETAILS_FILE_NAME
echo -e "${Yellow}Unix Pass: ${White}$UNIX_USER_PASS" | tee -a $DETAILS_FILE_NAME
echo -e "${Yellow}txAdmin Url: ${White}$txAdminUI OR http(s)://$TXADMIN_EXT_DOMAIN" | tee -a $DETAILS_FILE_NAME
echo -e "${Yellow}txAdmin Token: ${White}$txAdminToken" | tee -a $DETAILS_FILE_NAME
echo -e "${Yellow}txAdmin & Server IP: ${White}$txAdminIP" | tee -a $DETAILS_FILE_NAME
echo -e "${Yellow}Server Port (TCP/UDP): ${White}$QBC_SERVER_PORT" | tee -a $DETAILS_FILE_NAME
echo -e "${Green} Save those details in a secret place!${Color_Off}" | tee -a $DETAILS_FILE_NAME
echo -e "${White}= = = = = = [ ${Red} I M P O R T A N T   T O   R E A D  ! ! ! ${White} ] = = = = = =" | tee -a $DETAILS_FILE_NAME
echo -e "${Red} For security reasons, You are not be able to connect as ${White}root${Red} user anymore!" | tee -a $DETAILS_FILE_NAME
echo -e "${Red} at the next time you need to login as user ${White}$UNIX_USER${Red}" | tee -a $DETAILS_FILE_NAME
echo -e "${Cyan} To shutdown/restart your server, use systemd command, for Example: ${White}systemctl ${Green}start${White} qbcore.service${Red}" | tee -a $DETAILS_FILE_NAME
echo -e "${Cyan} The available options are: ${White}start/stop/enable/disable\n${Cyan}enable/disable - means that the service qbcore will automaticlly start when the is server power on.${Color_Off}" | tee -a $DETAILS_FILE_NAME
rm $0
