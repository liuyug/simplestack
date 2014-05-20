#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../admin-openrc.sh

NETWORK_CIDR="10.0.1.0/24"

nova network-create demo-net --bridge br100 --multi-host T \
    --fixed-range-v4 NETWORK_CIDR

# vim: ts=4 sw=4 et tw=79
