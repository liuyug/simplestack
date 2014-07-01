#!/bin/sh

set -o xtrace

cur_dir=`dirname  $(readlink -fn $0)`


. $cur_dir/../demo-openrc.sh

if [ "x$1" = "xclean" ]; then
    neutron router-gateway-clear demo-router
    neutron router-interface-delete demo-router demo-subnet
    neutron router-delete demo-router
    neutron subnet-delete demo-subnet
    neutron net-delete demo-net
    exit 0
fi


TENANT_NETWORK_GATEWAY="10.0.1.1"
TENANT_NETWORK_CIDR="10.0.1.0/24"

neutron net-create demo-net
neutron subnet-create demo-net --name demo-subnet \
    --dns-nameserver 8.8.8.8 \
    --gateway $TENANT_NETWORK_GATEWAY $TENANT_NETWORK_CIDR

neutron router-create demo-router
neutron router-interface-add demo-router demo-subnet
neutron router-gateway-set demo-router ext-net

# vim: ts=4 sw=4 et tw=79
