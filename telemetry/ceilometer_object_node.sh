#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

keystone role-create --name=ResellerAdmin
keystone user-role-add --tenant=service --user=ceilometer \
    --role=ResellerAdmin


RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`


conf_file="/etc/swift/proxy-server.conf"
ini_set $conf_file "filter:ceilometer" "use" "egg:ceilometer#swift"

ini_set $conf_file "pipeline:main" "pipeline" \
    "healthcheck cache authtoken keystoneauth ceilometer proxy-server"

service swift-proxy restart

# vim: ts=4 sw=4 et tw=79
