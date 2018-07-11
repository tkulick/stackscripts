#!/bin/bash
#
#<UDF name="pass" label="McMyAdmin Password">
# PASS=
#
# Version control: https://github.com/tkulick/stackscripts
#

# Added logging for debug purposes
exec >  >(tee -a /root/stackscript.log)
exec 2> >(tee -a /root/stackscript.log >&2)

# Install pre-reqs
export DEBIAN_FRONTEND=noninteractive
apt -q -y install git openjdk-8-jre-headless expect unzip

# Create a user for Spigot
adduser --disabled-password --gecos "" spigot
chown -R spigot:spigot /home/spigot

# Install McMyAdmin
cd /usr/local
wget http://mcmyadmin.com/Downloads/etc.zip
unzip etc.zip; rm etc.zip

su - spigot -c "mkdir /home/spigot/McMyAdmin"

# Setup a Bash script for the install
cat <<EOF >> /home/spigot/McMyAdmin/setup.sh
#!/bin/bash
cd /home/spigot/McMyAdmin
wget -O /home/spigot/McMyAdmin/MCMA2_glibc26_2.zip http://mcmyadmin.com/Downloads/MCMA2_glibc26_2.zip
unzip /home/spigot/McMyAdmin/MCMA2_glibc26_2.zip
rm /home/spigot/McMyAdmin/MCMA2_glibc26_2.zip
chmod +x /home/spigot/McMyAdmin/install.sh
/home/spigot/McMyAdmin/install.sh
/home/spigot/McMyAdmin/MCMA2_Linux_x86_64 -setpass $PASS -configonly -nonotice
tmux new -s McMyAdmin -d /home/spigot/McMyAdmin/MCMA2_Linux_x86_64
EOF

chown -R spigot:spigot /home/spigot

su - spigot -c "chmod +x /home/spigot/McMyAdmin/setup.sh && /home/spigot/McMyAdmin/setup.sh"

# Install and compile!
su - spigot -c "mkdir /home/spigot/BuildTools && mkdir /home/spigot/spigot"
su - spigot -c "wget -O ~/BuildTools/BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
su - spigot -c "git config --global --unset core.autocrlf"
su - spigot -c "java -jar ~/BuildTools/BuildTools.jar"

# Mark EULA as true and fire up the server
su - spigot -c "java -Xms1G -Xmx1G -XX:+UseConcMarkSweepGC -jar ~/spigot*.jar"
su - spigot -c "sed -i \"s/eula=false/eula=true/\" /home/spigot/eula.txt"

# Move Spigot jar
su - spigot -c "mv /home/spigot/spigot*.jar /home/spigot/McMyAdmin/Minecraft/"
