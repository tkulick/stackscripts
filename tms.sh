#!/bin/bash
#
#<UDF name="hostname" label="Hostname">
# HOSTNAME=
#
#<UDF name="fqdn" label="Fully Qualified Domain Name">
# FQDN=
#
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
apt -q -y install git openjdk-8-jre-headless

# Create a user for Spigot
adduser --disabled-password --gecos "" spigot
chown -R spigot:spigot /home/spigot

su - spigot -c "mkdir /home/spigot/BuildTools && mkdir /home/spigot/spigot"
su - spigot -c "wget -O ~/BuildTools/BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
su - spigot -c "git config --global --unset core.autocrlf"
su - spigot -c "java -jar ~/BuildTools/BuildTools.jar"
su - spigot -c "cp ~/BuildTools/BuildTools.jar ~/spigot/spigot.jar"
su - spigot -c "java -Xms1G -Xmx1G -XX:+UseConcMarkSweepGC -jar ~/spigot/spigot.jar"

