#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../functions.sh
pass_file=$cur_dir/../pass.lst

KEYSTONE_TOKEN=`ini_get $pass_file "default" "KEYSTONE_TOKEN"`
KEYSTONE_SERVER=`ini_get $pass_file "default" "KEYSTONE_SERVER"`

export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT="http://$KEYSTONE_SERVER:35357/v2.0"

# create admin
ADMIN_PASS=`gen_pass`
ADMIN_EMAIL="admin@localhost"

ini_set $pass_file "default" "ADMIN_PASS" $ADMIN_PASS
keystone user-create --name=admin --pass=$ADMIN_PASS --email=$ADMIN_EMAIL

keystone role-create --name=admin

keystone tenant-create --name=admin --description="Admin Tenant"

keystone user-role-add --user=admin --tenant=admin --role=admin

keystone user-role-add --user=admin --role=_member_ --tenant=admin

# create noraml user

DEMO_PASS=`gen_pass`
DEMO_EMAIL="demo@localhost"
keystone user-create --name=demo --pass=$DEMO_PASS --email=$DEMO_EMAIL

keystone tenant-create --name=demo --description="Demo Tenant"

keystone user-role-add --user=demo --role=_member_ --tenant=demo

# create service tenant
keystone tenant-create --name=service --description="Service Tenant"

# define service and api endpoint
keystone service-create --name=keystone --type=identity \
    --description="OpenStack Identity"

keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ identity / {print $2}') \
    --publicurl=http://$KEYSTONE_SERVER:5000/v2.0 \
    --internalurl=http://$KEYSTONE_SERVER:5000/v2.0 \
    --adminurl=http://$KEYSTONE_SERVER:35357/v2.0

unset OS_SERVICE_TOKEN
unset OS_SERVICE_ENDPOINT

echo <<EOF > $cur_dir/../admin-openrc.sh
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://$KEYSTONE_SERVER:35357/v2.0
EOF
# source admin-openrc.sh

# vim: ts=4 sw=4 et tw=79
