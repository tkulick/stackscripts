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
  
  # Setup MySQL with non-root user
  mysql -u root -p
    USE mysql;
    CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'pteropass';
    CREATE DATABASE panel;
    GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
    FLUSH PRIVILEGES;
    quit;

  php artisan p:environment:setup
  php artisan p:environment:database
  php artisan migrate --seed
  php artisan p:user:make
  chown -R www-data:www-data *
  echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1" >> gamecron
  crontab gamecron
  rm gamecron
  systemctl enable pteroq.service
  systemctl start pteroq
  ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
  service nginx restart

fi

# Start it up!
su - $GAMESERVER -c "/home/$GAMESERVER/$GAMESERVER start"

# Remove StackScript traces
# rm /root/stackscript.log
# rm /root/StackScript
