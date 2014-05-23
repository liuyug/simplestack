#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


SWIFT_USER="swift"
SWIFT_PASS=`gen_pass`
SWIFT_SERVER=`hostname -s`
SWIFT_HASH=`gen_pass`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

ini_set $stack_conf "swift" "host" $SWIFT_SERVER
ini_set $stack_conf "swift" "username" $SWIFT_USER
ini_set $stack_conf "swift" "password" $SWIFT_PASS
ini_set $stack_conf "swift" "hash" $SWIFT_HASH

mkdir -p /etc/swift
conf_file="/etc/swift/swift.conf"
ini_set $conf_file "swift-hash" "swift_hash_path_suffix" "$SWIFT_HASH"


export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

keystone user-delete $SWIFT_USER
keystone user-create --name=$SWIFT_USER --pass=$SWIFT_PASS \
    --email=$SWIFT_USER@$SWIFT_SERVER
keystone user-role-add --user=$SWIFT_USER --tenant=service --role=admin

keystone service-delete swift
keystone service-create --name=swift --type=object-store \
    --description="OpenStack Object Storage"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ object-store / {print $2}') \
    --publicurl=http://$SWIFT_SERVER:8080/v1/AUTH_%\(tenant_id\)s \
    --internalurl=http://$SWIFT_SERVER:8080/v1/AUTH_%\(tenant_id\)s \
    --adminurl=http://$SWIFT_SERVER:8080

# swift stat
# swift upload myfiles test.txt
# swift upload myfiles test2.txt
# swift download myfiles


# vim: ts=4 sw=4 et tw=79
