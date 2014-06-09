#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


CEILOMETER_USER=`ini_get $stack_conf "ceilometer" "username"`
CEILOMETER_PASS=`ini_get $stack_conf "ceilometer" "password"`
CEILOMETER_TOKEN=`ini_get $stack_conf "ceilometer" "token"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

RABBIT_USER=`ini_get $stack_conf "rabbit" "username"`
RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

apt-get install ceilometer-agent-compute -y

conf_file="/etc/nova/nova.conf"
ini_set $conf_file "DEFAULT" "instance_usage_audit" "True"
ini_set $conf_file "DEFAULT" "instance_usage_audit_period" "hour"
ini_set $conf_file "DEFAULT" "notify_on_state_change" "vm_and_task_state"
ini_set_multiline $conf_file "DEFAULT" "notification_driver" \
    "nova.openstack.common.notifier.rpc_notifier" \
    "ceilometer.compute.nova_notifier"

service nova-compute restart

conf_file="/etc/ceilometer/ceilometer.conf"
ini_set $conf_file "publisher" "metering_secret" "$CEILOMETER_TOKEN"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"
ini_set $conf_file "DEFAULT" "auth_strategy" "keystone"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$CEILOMETER_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$CEILOMETER_PASS"
ini_set $conf_file "service_credentials" "os_auth_url" \
    "http://$KEYSTONE_SERVER:5000/v2.0"
ini_set $conf_file "service_credentials" "os_username" "$CEILOMETER_USER"
ini_set $conf_file "service_credentials" "os_tenant_name" "service"
ini_set $conf_file "service_credentials" "os_password" "$CEILOMETER_PASS"

service ceilometer-agent-compute restart

# vim: ts=4 sw=4 et tw=79
