#!/bin/bash
#
#<UDF name="KEY_COUNTRY" label="Country">
# KEY_COUNTRY=
#
#<UDF name="KEY_PROVINCE" label="Province or State">
# KEY_PROVINCE=
#
#<UDF name="KEY_CITY" label="City">
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
sed -i s/KEY_CONFIG=.*/KEY_CONFIG=\"\$EASY_RSA/openssl-1.0.0.cnf\"/ /home/vpn/certificates/vars
sed -i s/KEY_COUNTRY=.*/KEY_COUNTRY=\"$KEY_COUNTRY\"/ /home/vpn/certificates/vars
sed -i s/KEY_PROVINCE=.*/KEY_PROVINCE=\"$KEY_PROVINCE\"/ /home/vpn/certificates/vars
sed -i s/KEY_CITY=.*/KEY_CITY=\"$KEY_CITY\"/ /home/vpn/certificates/vars
sed -i s/KEY_ORG=.*/KEY_ORG=\"$KEY_ORG\"/ /home/vpn/certificates/vars
sed -i s/KEY_EMAIL=.*/KEY_EMAIL=\"$KEY_EMAIL\"/ /home/vpn/certificates/vars
sed -i s/KEY_OU=.*/KEY_OU=\"$KEY_OU\"/ /home/vpn/certificates/vars

/home/vpn/certificates/clean-all && /home/vpn/certificates/build-ca
source vars
/home/vpn/certificates/build-key-server server
/home/vpn/certificates/build-dh
/usr/sbin/openvpn --genkey --secret /home/vpn/certificates/keys/ta.key
cp /home/vpn/certificates/keys/{server.crt,server.key,ca.crt,dh2048.pem,ta.key} /etc/openvpn
gzip -d -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf > /dev/null
EOF

# Execute the script under the vpn user
chown -R vpn:vpn /home/vpn
su - vpn -c "chmod +x /home/vpn/setup.sh && /home/vpn/setup.sh"

# Update firewall and network routing
ufw allow openvpn
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
sysctl -p /etc/sysctl.conf
ufw reload

# Fire up openVPN
systemctl start openvpn@server
