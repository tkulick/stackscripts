#!/bin/bash
#
#<UDF name="hostname" label="Hostname">
# HOSTNAME=
#
#<UDF name="fqdn" label="Fully Qualified Domain Name">
# FQDN=
#
#<udf name="gameserver" label="Game Server" oneOf="arkserver,arma3server,bb2server,bdserver,bf1942server,bmdmserver,boserver,bsserver,bt1944server,ccserver,cod2server,cod4server,codserver,coduoserver,codwawserver,csczserver,csgoserver,csserver,cssserver,dabserver,dmcserver,dodserver,dodsserver,doiserver,dstserver,emserver,etlserver,fctrserver,fofserver,gesserver,gmodserver,hl2dmserver,hldmserver,hldmsserver,hwserver,insserver,jc2server,jc3server,kf2server,kfserver,l4d2server,l4dserver,mcserver,mtaserver,mumbleserver,nmrihserver,ns2cserver,ns2server,opforserver,pcserver,pvkiiserver,pzserver,q2server,q3server,qlserver,qwserver,ricochetserver,roserver,rustserver,rwserver,sampserver,sbserver,sdtdserver,squadserver,ss3server,stserver,svenserver,terrariaserver,tf2server,tfcserver,ts3server,tuserver,twserver,ut2k4server,ut3server,ut99server,wetserver,zpsserver">
# GAMESERVER=
#
#<UDF name="gamename" label="Game Server Name">
# GAMENAME=
#
#<UDF name="email" label="Email Address">
# EMAIL=
#
#<UDF name="pteropass" label="Password">
# PTEROPASS=
#
# Version control: https://github.com/tkulick/game-stackscript
#

# Added logging for debug purposes
exec >  >(tee -a /root/stackscript.log)
exec 2> >(tee -a /root/stackscript.log >&2)

# This sets the variable $IPADDR to the IP address the new Linode receives.
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

# Install LinuxGSM and the Game Server of your choice
export DEBIAN_FRONTEND=noninteractive
dpkg --add-architecture i386
apt -q -y install mailutils postfix curl wget file bzip2 gzip unzip software-properties-common bsdmainutils python util-linux ca-certificates binutils bc tmux

#
# Game specific settings
#

# Minecraft 
if [ "$GAMESERVER" == "mcserver" ]
then
  add-apt-repository -y ppa:webupd8team/java
  apt -q -y remove openjdk-11*
  apt -q -y purge openjdk-11*
  apt -q -y install openjdk-8-jre-headless
  update-ca-certificates -f
fi

#
# Continuing with download, installation, setup, and execution of the game server
#

# Install fail2ban and update all packages
apt-get -q -y install fail2ban
apt-get update && apt-get -q -y dist-upgrade && apt-get -q -y autoremove

# Add a user for the game server
adduser --disabled-password --gecos "" $GAMESERVER

# Download and run the LinuxGSM script
wget https://linuxgsm.com/dl/linuxgsm.sh -P /home/$GAMESERVER/
chmod +x /home/$GAMESERVER/linuxgsm.sh
chown -R $GAMESERVER:$GAMESERVER /home/$GAMESERVER/*
su - $GAMESERVER -c "/home/$GAMESERVER/linuxgsm.sh $GAMESERVER"
su - $GAMESERVER -c "/home/$GAMESERVER/$GAMESERVER auto-install"

# Update the server IP and name
su - $GAMESERVER -c "sed -i \"s/server-ip=/server-ip=$IPADDR/\" /home/$GAMESERVER/serverfiles/server.properties"
su - $GAMESERVER -c "sed -i \"s/motd=.*/motd=$GAMENAME/\" /home/$GAMESERVER/serverfiles/server.properties"

# Add cron jobs for updating the game server and linuxgsm
crontab -l > gamecron
echo "0 23 * * * su - $GAMESERVER -c '/home/$GAMESERVER/$GAMESERVER update' > /dev/null 2>&1" >> gamecron
echo "30 23 * * * su - $GAMESERVER -c '/home/$GAMESERVER/$GAMESERVER update-functions' > /dev/null 2>&1" >> gamecron
crontab gamecron
rm gamecron

# Set hostname and FQDN
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname
echo $IPADDR $FQDN $HOSTNAME >> /etc/hosts

# If the game can be managed via Pterodactyl; install and run it!
# https://docs.pterodactyl.io/docs/downloading
if [ "$GAMESERVER" == "mcserver" ]
then
  add-apt-repository -y ppa:ondrej/php
  add-apt-repository -y ppa:chris-lea/redis-server
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
  apt update
  apt -q -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip mariadb-server nginx curl tar unzip git redis-server
  mkdir -p /var/www/pterodactyl
  cd /var/www/pterodactyl
  curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.9/panel.tar.gz
  tar --strip-components=1 -xzvf panel.tar.gz
  chmod -R 755 storage/* bootstrap/cache
  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
  cp .env.example .env
  composer install --no-dev
  php artisan key:generate --force
  
  # Setup MySQL with non-root user // interactive command
  dbpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 18 | head -n 1` 
  cat <<EOT > ptero.sql
    USE mysql;
    CREATE USER 'panel'@'127.0.0.1' IDENTIFIED BY '$dbpassword';
    CREATE DATABASE panel;
    GRANT ALL PRIVILEGES ON panel.* TO 'panel'@'127.0.0.1';
    FLUSH PRIVILEGES;
    QUIT;
EOT
  mysql -u root < ptero.sql
  rm ptero.sql
  echo "Password for DB is $dbpassword" >> /home/mcserver/ptero-pass.txt

  # Interactive commands
  php artisan p:environment:setup --url=http://$FQDN --timezone=America/New_York --author=$EMAIL --cache=redis --session=database --queue=database --disable-settings-ui -n
  php artisan p:environment:database --host=localhost --port=3306 --database=panel --username=panel --password=$dbpassword -n
  php artisan migrate --seed --force
  php artisan p:user:make --email="$EMAIL" --password=$PTEROPASS --admin=1 -n
  
  chown -R www-data:www-data *
  
  echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1" >> gamecron
  crontab gamecron
  rm gamecron
  
  cat <<EOT > /etc/systemd/system/pteroq.service
# Pterodactyl Queue Worker File
# ----------------------------------
# File should be placed in:
# /etc/systemd/system
#
# nano /etc/systemd/system/pteroq.service

[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
# On some systems the user and group might be different.
# Some systems use `apache` as the user and group.
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOT

  systemctl enable pteroq.service
  systemctl start pteroq

echo '
    server {
        listen 80;
        listen [::]:80;
        server_name '"${FQDN}"';
    
        root "/var/www/pterodactyl/html/public";
        index index.html index.htm index.php;
        charset utf-8;
    
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
    
        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }
    
        access_log off;
        error_log  /var/log/nginx/pterodactyl.app-error.log error;
    
        # allow larger file uploads and longer script runtimes
            client_max_body_size 100m;
        client_body_timeout 120s;
    
        sendfile off;
    
        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_intercept_errors off;
            fastcgi_buffer_size 16k;
            fastcgi_buffers 4 16k;
            fastcgi_connect_timeout 300;
            fastcgi_send_timeout 300;
            fastcgi_read_timeout 300;
        }
    
        location ~ /\.ht {
            deny all;
        }
        location ~ /.well-known {
            allow all;
        }
    }
' | tee /etc/nginx/sites-available/pterodactyl.conf >/dev/null 2>&1

    ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
    service nginx restart
    apt -q -y install letsencrypt
    letsencrypt certonly -a webroot --webroot-path=/var/www/pterodactyl/public --email "$EMAIL" --agree-tos -d "$FQDN" -n
    rm /etc/nginx/sites-available/pterodactyl.conf
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    echo '
        server {
            listen 80;
            listen [::]:80;
            server_name '"${FQDN}"';
            # enforce https
            return 301 https://$server_name$request_uri;
        }
        
        server {
            listen 443 ssl http2;
            listen [::]:443 ssl http2;
            server_name '"${FQDN}"';
        
            root /var/www/pterodactyl/html/public;
            index index.php;
        
            access_log /var/log/nginx/pterodactyl.app-accress.log;
            error_log  /var/log/nginx/pterodactyl.app-error.log error;
        
            # allow larger file uploads and longer script runtimes
            client_max_body_size 100m;
            client_body_timeout 120s;
            
            sendfile off;
        
            # strengthen ssl security
            ssl_certificate /etc/letsencrypt/live/'"${FQDN}"'/fullchain.pem;
            ssl_certificate_key /etc/letsencrypt/live/'"${FQDN}"'/privkey.pem;
            ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
            ssl_prefer_server_ciphers on;
            ssl_session_cache shared:SSL:10m;
            ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
            ssl_dhparam /etc/ssl/certs/dhparam.pem;
        
            # Add headers to serve security related headers
            add_header Strict-Transport-Security "max-age=15768000; preload;";
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Robots-Tag none;
            add_header Content-Security-Policy "frame-ancestors 'self'";
        
            location / {
                    try_files $uri $uri/ /index.php?$query_string;
              }
        
            location ~ \.php$ {
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_intercept_errors off;
                fastcgi_buffer_size 16k;
                fastcgi_buffers 4 16k;
                fastcgi_connect_timeout 300;
                fastcgi_send_timeout 300;
                fastcgi_read_timeout 300;
                include /etc/nginx/fastcgi_params;
            }
        
            location ~ /\.ht {
                deny all;
            }
        }
    ' | tee /etc/nginx/sites-available/pterodactyl.conf >/dev/null 2>&1    

   service nginx restart  
  
  # Installing the daemons
  apt -q -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
  apt -y update
  curl -sSL https://get.docker.com/ | sh
  usermod -aG docker $GAMESERVER
  systemctl enable docker
  curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
  apt -q -y install nodejs
  mkdir -p /srv/daemon /srv/daemon-data
  chown -R $GAMESERVER:$GAMESERVER /srv/daemon
  cd /srv/daemon
  curl -Lo v0.3.7.tar.gz https://github.com/Pterodactyl/Daemon/archive/v0.3.7.tar.gz
  tar --strip-components=1 -xzvf v0.3.7.tar.gz
  npm install --only=production
  
  bash -c 'cat > /etc/systemd/system/wings.service' <<-EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
[Service]
User=root
#Group=some_group
WorkingDirectory=/srv/daemon
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/bin/node /srv/daemon/src/index.js
Restart=on-failure
StartLimitInterval=600
[Install]
WantedBy=multi-user.target
EOF

      sudo systemctl daemon-reload
      sudo systemctl enable wings
      sudo systemctl start wings
      sudo service wings start

      sudo usermod -aG www-data $GAMESERVER
      sudo chown -R www-data:www-data /var/www/pterodactyl/html
      sudo chown -R www-data:www-data /srv/daemon
      sudo chmod -R 775 /var/www/pterodactyl/html
      sudo chmod -R 775 /srv/daemon
      echo '
[client]
user=root
password='"${PTEROPASS}"'
[mysql]
user=root
password='"${PTEROPASS}"'
' | sudo -E tee ~/.my.cnf >/dev/null 2>&1
      sudo chmod 0600 ~/.my.cnf
      sudo mysqladmin -u root password $PTEROPASS 
fi

# Start it up!
su - $GAMESERVER -c "/home/$GAMESERVER/$GAMESERVER start"

# Remove StackScript traces
# rm /root/stackscript.log
# rm /root/StackScript
