#!/bin/bash
#
#<UDF name="hostname" label="Hostname" example="Local hostname">
# HOSTNAME=
#
#<UDF name="fqdn" label="Fully Qualified Domain Name" example="Provide the domain name you'd like to use for your server">
# FQDN=
#
# Version control: https://github.com/tkulick/stackscripts
#

# Update packages
apt-get -y update && apt-get -y dist-upgrade && apt-get -y autoremove

# Grab the Plex installation file
wget -O plex.deb https://downloads.plex.tv/plex-media-server-new/1.15.3.835-5d4a5c895/debian/plexmediaserver_1.15.3.835-5d4a5c895_amd64.deb

# Install Plex
dpkg -i plex.deb
