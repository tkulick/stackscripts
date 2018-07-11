
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

# Installation
export DEBIAN_FRONTEND=noninteractive
apt -q -y install openvpn easy-rsa

# Create a user for VPN
adduser --disabled-password --gecos "" vpn
chown -R vpn:vpn /home/vpn

# Setup a Bash script for the install
cat <<EOF >> /home/vpn/setup.sh
#!/bin/bash
make-cadir certificates && cd certificates
source vars
./clean-all && ./build-ca
./build-key-server server
./build-dh
openvpn --genkey --secret keys/ta.key
cp keys/{server.crt,server.key,ca.crt,dh2048.pem,ta.key} /etc/openvpn
gzip -d -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf > /dev/null
EOF

# Execute the script under the vpn user
su - vpn -c "chmod+x /home/vpn/setup.sh && /home/vpn/setup.sh"

# Update firewall and network routing
ufw allow openvpn
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
sysctl -p /etc/sysctl.conf
ufw reload

# Fire up openVPN
systemctl start openvpn@server
