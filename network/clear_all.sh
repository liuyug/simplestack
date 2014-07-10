#!/bin/sh

set -o xtrace

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../admin-openrc.sh

# Extrnal network
# The admin tenant owns this network because it provides external network
# access for multiple tenants.
neutron router-gateway-clear demo-router
neutron router-interface-delete demo-router demo-subnet
neutron router-delete demo-router

neutron subnet-delete ext-subnet
neutron net-delete ext-net

# Tenant network (internal network)
# The demo tenant owns this network because it only provides network access for
# instances within it.

neutron subnet-delete demo-subnet
neutron net-delete demo-net


# vim: ts=4 sw=4 et tw=79
