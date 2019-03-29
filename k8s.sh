#!/bin/bash
#
#<UDF name="cluster" label="Cluster Name" example="mycluster">
# CLUSTER=
#
# Version control: https://github.com/tkulick/stackscripts
#


#
pip install linode-cli

#
linode-cli k8s-alpha create $CLUSTER
