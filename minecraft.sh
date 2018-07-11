#!/bin/bash
#
#<UDF name="hostname" label="Hostname">
# HOSTNAME=
#
#<UDF name="fqdn" label="Fully Qualified Domain Name">
# FQDN=
#
#<UDF name="pass" label="McMyAdmin Password">
# PASS=
#
#<UDF name="gamename" label="Game Server Name">
# GAMENAME=
#
# Version control: https://github.com/tkulick/stackscripts
#

# Added logging for debug purposes
exec >  >(tee -a /root/stackscript.log)
exec 2> >(tee -a /root/stackscript.log >&2)

# This sets the variable $IPADDR to the IP address the new Linode receives.
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

# Install pre-reqs
export DEBIAN_FRONTEND=noninteractive
apt -q -y install git openjdk-8-jre-headless expect unzip

# Create a user for Spigot
adduser --disabled-password --gecos "" spigot
chown -R spigot:spigot /home/spigot

# Install and compile!
su - spigot -c "mkdir /home/spigot/BuildTools && mkdir /home/spigot/spigot"
su - spigot -c "wget -O ~/BuildTools/BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
su - spigot -c "git config --global --unset core.autocrlf"
su - spigot -c "java -jar ~/BuildTools/BuildTools.jar"

# Mark EULA as true and fire up the server
su - spigot -c "java -Xms1G -Xmx1G -XX:+UseConcMarkSweepGC -jar ~/spigot*.jar"
su - spigot -c "sed -i \"s/eula=false/eula=true/\" /home/spigot/eula.txt"

# Commenting out Spigot launch since McMyAdmin will launch the server
#su - spigot -c "tmux new -s spigot -d 'java -Xms1G -Xmx1G -XX:+UseConcMarkSweepGC -jar /home/spigot/spigot*.jar'"

# Install McMyAdmin
cd /usr/local
wget http://mcmyadmin.com/Downloads/etc.zip
unzip etc.zip; rm etc.zip

su - spigot -c "mkdir ~/McMyAdmin"
su - spigot -c "wget -O /home/spigot/McMyAdmin/MCMA2_glibc26_2.zip http://mcmyadmin.com/Downloads/MCMA2_glibc26_2.zip"
su - spigot -c "unzip /home/spigot/McMyAdmin/MCMA2_glibc26_2.zip"
su - spigot -c "rm /home/spigot/McMyAdmin/MCMA2_glibc26_2.zip"

# Setup an Expect script for the install
cat <<EOT >> /home/spigot/McMyAdmin/install.sh
#!/usr/bin/expect
spawn /home/spigot/McMyAdmin/MCMA2_Linux_x86_64 -setpass $PASS -configonly
expect {
"n\] : " {send "y"
exp_continue}
}
EOT

chown -R spigot:spigot /home/spigot

su - spigot -c "chmod +x /home/spigot/McMyAdmin/install.sh"
su - spigot -c "mv /home/spigot/MCMA2_Linux_x86_64 /home/spigot/McMyAdmin/"
su - spigot -c "/home/spigot/McMyAdmin/install.sh"
su - spigot -c "tmux new -s McMyAdmin -d /home/spigot/McMyAdmin/MCMA2_Linux_x86_64"
