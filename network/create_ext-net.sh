#!/bin/sh

set -o xtrace

cur_dir=`dirname  $(readlink -fn $0)`


. $cur_dir/../admin-openrc.sh

if [ "x$1" = "xclean" ]; then
    neutron router-gateway-clear demo-router
    neutron subnet-delete ext-subnet
    neutron net-delete ext-net
    exit 0
fi

FLOATING_IP_START="9.111.57.245"
FLOATING_IP_END="9.111.57.249"
EXTERNAL_NETWORK_GATEWAY="9.111.57.1"
EXTERNAL_NETWORK_CIDR="9.111.57.0/24"

tenant_id=`keystone tenant-list | awk '/ admin /{print $2}'`
neutron net-create ext-net \
    --tenant_id=$tenant_id \
    --router:external=True \
    --provider:network_type=flat \
    --provider:physical_network=phyext \


neutron subnet-create ext-net --name ext-subnet \
    --tenant_id=$tenant_id \
    --disable-dhcp \
    --allocation-pool start=$FLOATING_IP_START,end=$FLOATING_IP_END \
    --gateway $EXTERNAL_NETWORK_GATEWAY \
    $EXTERNAL_NETWORK_CIDR

#    --no-gateway \
#    --host-route destination=0.0.0.0/0,nexthop=$EXTERNAL_NETWORK_GATEWAY \


# vim: ts=4 sw=4 et tw=79
