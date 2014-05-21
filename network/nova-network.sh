#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

apt-get remove nova-network -y
apt-get install nova-network -y

conf_file="/etc/nova/nova.conf"
ini_set $conf_file "DEFAULT" "network_api_class" "nova.network.api.API"
ini_set $conf_file "DEFAULT" "security_group_api" "nova"

service nova-api restart
service nova-scheduler restart
service nova-conductor restart

service nova-network restart

# vim: ts=4 sw=4 et tw=79
