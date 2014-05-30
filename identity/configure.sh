#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

echo -n "Wait keystone service ready"
while keystone user-list >/dev/null 2>&1; do
    echo -n "."
    sleep 1s
done
echo ""

# create admin
ADMIN_PASS=`gen_pass`
ADMIN_EMAIL="admin@$KEYSTONE_SERVER"

ini_set $stack_conf "keystone" "admin_username" "admin"
ini_set $stack_conf "keystone" "admin_password" "$ADMIN_PASS"

keystone user-delete admin
keystone user-create --name=admin --pass=$ADMIN_PASS --email=$ADMIN_EMAIL

keystone role-delete admin
keystone role-create --name=admin

keystone tenant-delete admin
keystone tenant-create --name=admin --description="Admin Tenant"

keystone user-role-add --user=admin --tenant=admin --role=admin

keystone user-role-add --user=admin --role=_member_ --tenant=admin

# create noraml user

DEMO_PASS=`gen_pass`
DEMO_EMAIL="demo@$KEYSTONE_SERVER"

ini_set $stack_conf "keystone" "demo_username" "demo"
ini_set $stack_conf "keystone" "demo_password" "$DEMO_PASS"

keystone user-delete demo
keystone user-create --name=demo --pass=$DEMO_PASS --email=$DEMO_EMAIL

keystone tenant-delete demo
keystone tenant-create --name=demo --description="Demo Tenant"

keystone user-role-add --user=demo --role=_member_ --tenant=demo

# create service tenant
keystone tenant-delete service
keystone tenant-create --name=service --description="Service Tenant"

# define service and api endpoint
keystone service-delete keystone
keystone service-create --name=keystone --type=identity \
    --description="OpenStack Identity"

keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ identity / {print $2}') \
    --publicurl=http://$KEYSTONE_SERVER:5000/v2.0 \
    --internalurl=http://$KEYSTONE_SERVER:5000/v2.0 \
    --adminurl=http://$KEYSTONE_SERVER:35357/v2.0

# check
keystone user-list

unset OS_SERVICE_TOKEN
unset OS_SERVICE_ENDPOINT

$cur_dir/../mkrc.sh "$KEYSTONE_SERVER" "admin" "$ADMIN_PASS" "admin" \
    > $cur_dir/../admin-openrc.sh

$cur_dir/../mkrc.sh "$KEYSTONE_SERVER" "demo" "$DEMO_PASS" "demo" \
    > $cur_dir/../demo-openrc.sh


# vim: ts=4 sw=4 et tw=79
