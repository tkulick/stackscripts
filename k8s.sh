#!/bin/sh
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

# Add SSH directory and update pub key
mkdir .ssh
echo $PUBKEY > .ssh/id_rsa.pub

# Download and install pip and the Linode CLI
apk add py-pip
pip install linode-cli

# Install cluster
linode-cli k8s-alpha create $CLUSTER --node-type $NODETYPE --nodes $NODECOUNT --master-type $MASTERTYPE --region $REGION --ssh-public-key $HOME/.ssh/id_rsa.pub options --api-key $TOKEN

