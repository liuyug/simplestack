#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../../functions.sh
stack_conf=$cur_dir/../../stack.conf

. $cur_dir/../../admin-openrc.sh

if [ "x$1" = "xclean" ]; then
    neutron subnet-delete ext-subnet
    neutron net-delete ext-net
    exit 0
fi

FLOATING_IP_START=`ini_get $stack_conf "neutron" "floating_ip_start"`
FLOATING_IP_END=`ini_get $stack_conf "neutron" "floating_ip_end"`
EXTERNAL_NETWORK_GATEWAY=`ini_get $stack_conf "neutron" "external_network_gateway"`
EXTERNAL_NETWORK_CIDR=`ini_get $stack_conf "neutron" "external_network_cidr"`

tenant_id=`keystone tenant-list | awk '/ admin /{print $2}'`
neutron net-create ext-net \
    --shared \
    --tenant_id=$tenant_id \
    --provider:network_type=flat \
    --provider:physical_network=phydemo

neutron subnet-create ext-net --name ext-subnet \
    --tenant_id=$tenant_id \
    --dns-nameserver 8.8.8.8 \
    --allocation-pool start=$FLOATING_IP_START,end=$FLOATING_IP_END \
    --gateway $EXTERNAL_NETWORK_GATEWAY \
    $EXTERNAL_NETWORK_CIDR

# vim: ts=4 sw=4 et tw=79
