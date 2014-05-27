#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

conf_file="/etc/cinder/cinder.conf"
ini_set $conf_file "DEFAULT" "control_exchange" "cinder"
ini_set $conf_file "DEFAULT" "notification_driver" \
    "cinder.openstack.common.notifier.rpc_notifier"

service cinder-api restart
service cinder-scheduler restart
service cinder-volume restart

# vim: ts=4 sw=4 et tw=79
