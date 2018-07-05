#!/bin/bash
#
#<UDF name="hostname" label="Hostname">
# HOSTNAME=
#
#<UDF name="fqdn" label="Fully Qualified Domain Name">
# FQDN=
#
# Version control: https://github.com/tkulick/stackscripts
#

# Added logging for debug purposes
exec >  >(tee -a /root/stackscript.log)
exec 2> >(tee -a /root/stackscript.log >&2)

# This sets the variable $IPADDR to the IP address the new Linode receives.
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

# Set to non-interactive and install core packages
export DEBIAN_FRONTEND=noninteractive
apt -q -y install php-curl php-gd php-mbstring php-xml php-xmlrpc mysql

# Login as root to mysql and create initial DB

# Install fail2ban and update all packages
apt-get -q -y install fail2ban

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

# Set hostname and FQDN
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname
echo $IPADDR $FQDN $HOSTNAME >> /etc/hosts

# Remove StackScript traces
# rm /root/stackscript.log
# rm /root/StackScript
