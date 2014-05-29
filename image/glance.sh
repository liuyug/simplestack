#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

# generate parameter
GLANCE_DBUSER="glance"
GLANCE_DBPASS=`gen_pass`
GLANCE_SERVER=`hostname -s`
GLANCE_USER="glance"
GLANCE_PASS=`gen_pass`

# external parameter
DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

RABBIT_USER=`ini_get $stack_conf "rabbit" "username"`
RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

ini_set $stack_conf "glance" "db_username" $GLANCE_DBUSER
ini_set $stack_conf "glance" "db_password" $GLANCE_DBPASS
ini_set $stack_conf "glance" "host" "$GLANCE_SERVER"
ini_set $stack_conf "glance" "username" "$GLANCE_USER"
ini_set $stack_conf "glance" "password" "$GLANCE_PASS"

# install db client
apt-get install python-mysqldb -y
apt-get install glance python-glanceclient -y

conf_file="/etc/glance/glance-api.conf"
ini_set $conf_file "database" "connection" \
    "mysql://$GLANCE_DBUSER:$GLANCE_DBPASS@$DB_SERVER/glance"
ini_set $conf_file "DEFAULT" "rpc_backend" "rabbit"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"
ini_set $conf_file "DEFAULT" "known_stores" "glance.store.filesystem.Store"
ini_set $conf_file "DEFAULT" "verbose" "True"


conf_file="/etc/glance/glance-registry.conf"
ini_set $conf_file "database" "connection" \
    "mysql://$GLANCE_DBUSER:$GLANCE_DBPASS@$DB_SERVER/glance"

rm -rf /var/lib/glance/glance.sqlite

# create glance database
mysql -u root -p$DB_ROOT_PASS <<EOF
DROP DATABASE IF EXISTS glance;
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO '$GLANCE_DBUSER'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO '$GLANCE_DBUSER'@'%' IDENTIFIED BY '$GLANCE_DBPASS';
EOF

# create glance tables
su -s /bin/sh -c "glance-manage db_sync" glance

export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

# create glance user in keystone
keystone user-delete $GLANCE_USER
keystone user-create --name=$GLANCE_USER --pass=$GLANCE_PASS \
    --email=$GLANCE_USER@$GLANCE_SERVER
keystone user-role-add --user=$GLANCE_USER --tenant=service --role=admin


conf_file="/etc/glance/glance-api.conf"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$GLANCE_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$GLANCE_PASS"
ini_set $conf_file "paste_deploy" "flavor" "keystone"

conf_file="/etc/glance/glance-registry.conf"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$GLANCE_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$GLANCE_PASS"
ini_set $conf_file "paste_deploy" "flavor" "keystone"

# Register the Image Service with the Identity service so that other OpenStack
# services can locate it.
keystone service-delete glance
keystone service-create --name=$GLANCE_USER --type=image \
    --description="OpenStack Image Service"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ image / {print $2}') \
    --publicurl=http://$GLANCE_SERVER:9292 \
    --internalurl=http://$GLANCE_SERVER:9292 \
    --adminurl=http://$GLANCE_SERVER:9292

service glance-registry restart
service glance-api restart

# vim: ts=4 sw=4 et tw=79
