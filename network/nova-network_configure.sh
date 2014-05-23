#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../admin-openrc.sh

NETWORK_CIDR="10.0.1.0/24"

nova net-delete $(nova net-list | awk '/ demo-net / { printf $2}')
nova network-create demo-net --bridge br100 --multi-host T \
    --fixed-range-v4 "$NETWORK_CIDR"

# check
nova net-list

nova secgroup-list
# permit icmp
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
# permit ssh
nova  secgroup-add-rule default tcp 22 22 0.0.0.0/0
# permit vm access external network
# iptables -t nat -A POSTROUTING -o br100 -j MASQUERADE

# vim: ts=4 sw=4 et tw=79
