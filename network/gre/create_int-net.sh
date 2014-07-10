#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../../functions.sh
stack_conf=$cur_dir/../../stack.conf

. $cur_dir/../../admin-openrc.sh


if [ "x$1" = "xclean" ]; then
    neutron router-gateway-clear demo-router
    neutron router-interface-delete demo-router demo-subnet
    neutron router-delete demo-router
    neutron subnet-delete demo-subnet
    neutron net-delete demo-net
    exit 0
fi


TENANT_NETWORK_GATEWAY=`ini_get $stack_conf "neutron" "tenant_network_gateway"`
TENANT_NETWORK_CIDR=`ini_get $stack_conf "neutron" "tenant_network_cidr"`

tenant_id=`keystone tenant-list | awk '/ demo /{print $2}'`
neutron net-create demo-net \
    --tenant_id=$tenant_id

neutron subnet-create demo-net \
    --name demo-subnet \
    --tenant_id=$tenant_id \
    --dns-nameserver 8.8.8.8 \
    --gateway $TENANT_NETWORK_GATEWAY \
    $TENANT_NETWORK_CIDR

neutron router-create demo-router \
    --tenant_id=$tenant_id

neutron router-interface-add demo-router demo-subnet
neutron router-gateway-set demo-router ext-net

# vim: ts=4 sw=4 et tw=79
