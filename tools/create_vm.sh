#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../demo-openrc.sh

set -o xtrace

VM_NAME=$1
IMG_NAME=$2
NET_ID=$3

nova boot --flavor m1.tiny --image $IMG_NAME --nic net-id=$NET_ID \
      --security-group default --key-name default $VM_NAME

# vim: ts=4 sw=4 et tw=79
