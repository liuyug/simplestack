#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


RABBIT_USER=`ini_get $stack_conf "rabbit" "username"`
RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`


conf_file="/etc/glance/glance-api.conf"
ini_set $conf_file "DEFAULT" "notification_driver" "messaging"
ini_set $conf_file "DEFAULT" "rpc_backend" "rabbit"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"

service glance-registry restart
service glance-api restart

# vim: ts=4 sw=4 et tw=79
