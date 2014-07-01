#!/bin/sh

set -o xtrace

cur_dir=`dirname  $(readlink -fn $0)`


# Extrnal network
# The admin tenant owns this network because it provides external network
# access for multiple tenants.
FLOATING_IP_START="192.168.200.100"
FLOATING_IP_END="192.168.200.150"
EXTERNAL_NETWORK_GATEWAY="192.168.200.1"
EXTERNAL_NETWORK_CIDR="192.168.200.0/24"


. $cur_dir/../demo-openrc.sh
neutron router-gateway-clear demo-router

. $cur_dir/../admin-openrc.sh
neutron subnet-delete ext-subnet
neutron net-delete ext-net

neutron net-create ext-net --shared --router:external=True
neutron subnet-create ext-net --name ext-subnet \
    --allocation-pool start=$FLOATING_IP_START,end=$FLOATING_IP_END \
    --disable-dhcp --gateway $EXTERNAL_NETWORK_GATEWAY $EXTERNAL_NETWORK_CIDR

# Tenant network (internal network)
# The demo tenant owns this network because it only provides network access for
# instances within it.
. $cur_dir/../demo-openrc.sh

TENANT_NETWORK_GATEWAY="10.0.1.1"
TENANT_NETWORK_CIDR="10.0.1.0/24"

neutron router-interface-delete demo-router demo-subnet
neutron subnet-delete demo-subnet
neutron net-delete demo-net

neutron router-delete demo-router

neutron net-create demo-net
neutron subnet-create demo-net --name demo-subnet \
    --gateway $TENANT_NETWORK_GATEWAY $TENANT_NETWORK_CIDR

neutron router-create demo-router
neutron router-interface-add demo-router demo-subnet
neutron router-gateway-set demo-router ext-net

# verify network
# ping gateway

# vim: ts=4 sw=4 et tw=79
