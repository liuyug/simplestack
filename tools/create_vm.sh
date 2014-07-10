#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../demo-openrc.sh

set -o xtrace

if [ $# -lt 3 ]; then
    echo "$(basename $0) <vm name> <image name> <network name>"
    exit 1
fi

VM_NAME=$1
IMG_NAME=$2
NET_NAME=$3
NET_ID=`neutron net-list | awk "/ $NET_NAME /{print \\\$2}"`

nova boot --flavor m1.tiny --image $IMG_NAME --nic net-id=$NET_ID \
      --security-group default --key-name default $VM_NAME

# vim: ts=4 sw=4 et tw=79
