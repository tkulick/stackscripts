#!/bin/sh
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

# Download and install pip and the Linode CLI
apk add py-pip
pip install linode-cli

#
linode-cli k8s-alpha create $CLUSTER --node-type $NODETYPE --nodes $NODECOUNT --master-type $MASTERTYPE --region $REGION --ssh-public-key $TOKEN

