#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


apt-get install lvm2 -y
# pvcreate /dev/sdb
# vgcreate cinder-volumes /dev/sdb

# /etc/lvm/lvm.conf
# devices {
# ...
# filter = [ "a/sda1/", "a/sdb/", "r/.*/"]
# ...
# }
CINDER_VOLUMES="cinder_volumes_file"
dd if=/dev/zero of=$cur_dir/$CINDER_VOLUMES bs=1G count=10
losetup -f $cur_dir/$CINDER_VOLUMES
CINDER_DEVICE=`losetup -j $cur_dir/$CINDER_VOLUMES | cut -d":" -f1`
pvcreate $CINDER_DEVICE
vgcreate cinder-volumes $CINDER_DEVICE

apt-get install cinder-volume -y

CINDER_USER=`ini_get $stack_conf "cinder" "username"`
CINDER_PASS=`ini_get $stack_conf "cinder" "password"`
CINDER_DBUSER=`ini_get $stack_conf "cinder" "db_username"`
CINDER_DBPASS=`ini_get $stack_conf "cinder" "db_password"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

GLANCE_SERVER=`ini_get $stack_conf "glance" "host"`

conf_file="/etc/cinder/cinder.conf"
ini_set $conf_file "database" "connection" \
    "mysql://$CINDER_DBUSER:$CINDER_DBPASS@$DB_SERVER/cinder"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$CINDER_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$CINDER_PASS"
ini_set $conf_file "DEFAULT" "rpc_backend" \
    "cinder.openstack.common.rpc.impl_kombu"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_port" "5672"
ini_set $conf_file "DEFAULT" "rabbit_userid" "guest"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"
ini_set $conf_file "DEFAULT" "glance_host" "$GLANCE_SERVER"

service cinder-volume restart
service tgt restart

# check
. $cur_dir/../demo-openrc.sh
cinder create --display-name testVolume 1
cinder list
cinder delete testVolume

# vim: ts=4 sw=4 et tw=79
