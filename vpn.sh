
#!/bin/bash
#
#<UDF name="hostname" label="Hostname">
# HOSTNAME=
#
#<UDF name="fqdn" label="Fully Qualified Domain Name">
# FQDN=
#
#<UDF name="KEY_CONFIG" label="Key configuration">
# KEY_CONFIG=
#
#<UDF name="KEY_COUNTRY" label="Country">
# KEY_COUNTRY=
#
#<UDF name="KEY_PROVINCE" label="Province or State">
# KEY_PROVINCE=
#
#<UDF name="KEY_CITY" label="CITY">
# KEY_CITY=
#
#<UDF name="KEY_ORG" label="Organization">
# KEY_ORG=
#
#<UDF name="KEY_EMAIL" label="Email Address">
# KEY_EMAIL=
#
#<UDF name="KEY_OU" label="Organizational Unit">
# KEY_OU=
#
# Source guide: https://linuxconfig.org/openvpn-setup-on-ubuntu-18-04-bionic-beaver-linux
# Version control: https://github.com/tkulick/stackscripts
#

# Added logging for debug purposes
exec >  >(tee -a /root/stackscript.log)
exec 2> >(tee -a /root/stackscript.log >&2)

# This sets the variable $IPADDR to the IP address the new Linode receives.
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

# Installation
export DEBIAN_FRONTEND=noninteractive
apt -q -y install openvpn easy-rsa


make-cadir certificates && cd certificates
source vars
./clean-all && ./build-ca
./build-key-server server
./build-dh
openvpn --genkey --secret keys/ta.key
cp keys/{server.crt,server.key,ca.crt,dh2048.pem,ta.key} /etc/openvpn

gzip -d -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf > /dev/null

ufw allow openvpn



systemctl start openvpn@server
