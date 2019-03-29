#!/bin/bash
#
# Version control: https://github.com/tkulick/stackscripts
#

# Update packages
apt-get -y update && apt-get -y dist-upgrade && apt-get -y autoremove

# Grab the Plex installation file
wget -O plex.deb https://downloads.plex.tv/plex-media-server-new/1.15.3.835-5d4a5c895/debian/plexmediaserver_1.15.3.835-5d4a5c895_amd64.deb

# Install Plex
dpkg -i plex.deb
