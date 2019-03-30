#!/bin/bash
#
#
#<UDF name="pubkey" label="SSH Public Key">
# PUBKEY=
#
#<UDF name="cluster" label="Cluster Name" example="mycluster">
# CLUSTER=
#
#<UDF name="token" label="Personal Access Token">
# TOKEN=
#
#<UDF name="nodetype" label="Node Type">
# NODETYPE=
#
#<UDF name="nodes" label="Node Count">
# NODECOUNT=
#
#<UDF name="master" label="Master Type">
# MASTERTYPE=
#
#<UDF name="region" label="region">
# REGION=
#
# Version control: https://github.com/tkulick/stackscripts
#

# Add one click apps helper
source <ssinclude StackScriptID="401712">

# Add SSH directory and update pub key
if [[ "$PUBKEY" != "" ]]; then
  add_pubkey
fi

# Download and install pip and the Linode CLI
apt-get update && apt-get -y dist-upgrade && apt-get -y autoremove
apt install -y python-pip terraform kubernetes
snap install kubectl --classic
pip install linode-cli

# Install cluster
LINODE_CLI_TOKEN=$TOKEN linode-cli k8s-alpha create $CLUSTER --node-type $NODETYPE --nodes $NODECOUNT --master-type $MASTERTYPE --region $REGION --ssh-public-key $HOME/.ssh/id_rsa.pub

