#!/bin/bash
#
#<UDF name="hostname" label="Hostname" example="Local hostname">
# HOSTNAME=
#
#<UDF name="fqdn" label="Fully Qualified Domain Name" example="Provide the domain name you'd like to use for your server">
# FQDN=
#
#<udf name="gameserver" label="Game Server" oneOf="arkserver,arma3server,bb2server,bdserver,bf1942server,bmdmserver,boserver,bsserver,bt1944server,ccserver,cod2server,cod4server,codserver,coduoserver,codwawserver,csczserver,csgoserver,csserver,cssserver,dabserver,dmcserver,dodserver,dodsserver,doiserver,dstserver,emserver,etlserver,fctrserver,fofserver,gesserver,gmodserver,hl2dmserver,hldmserver,hldmsserver,hwserver,insserver,jc2server,jc3server,kf2server,kfserver,l4d2server,l4dserver,mcserver,mtaserver,mumbleserver,nmrihserver,ns2cserver,ns2server,opforserver,pcserver,pvkiiserver,pzserver,q2server,q3server,qlserver,qwserver,ricochetserver,roserver,rustserver,rwserver,sampserver,sbserver,sdtdserver,squadserver,ss3server,stserver,svenserver,terrariaserver,tf2server,tfcserver,ts3server,tuserver,twserver,ut2k4server,ut3server,ut99server,wetserver,zpsserver" example="Select your game for your game server">
# GAMESERVER=
#
#<UDF name="gamename" label="Game Server Name" example="Name of the game server within your game">
# GAMENAME=
#
# Version control: https://github.com/tkulick/stackscripts
#

# Added logging for debug purposes
exec >  >(tee -a /root/stackscript.log)
exec 2> >(tee -a /root/stackscript.log >&2)
