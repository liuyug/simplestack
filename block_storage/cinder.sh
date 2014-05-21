#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


CINDER_DBUSER="cinder"
CINDER_DBPASS=`gen_pass`
CINDER_USER="cinder"
CINDER_PASS=`gen_pass`
CINDER_SERVER=`hostname -s`

DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

ini_set $stack_conf "cinder" "db_username" $CINDER_DBUSER
ini_set $stack_conf "cinder" "db_password" $CINDER_DBPASS
ini_set $stack_conf "cinder" "host" $CINDER_SERVER
ini_set $stack_conf "cinder" "username" $CINDER_USER
ini_set $stack_conf "cinder" "password" $CINDER_PASS


apt-get install cinder-api cinder-scheduler -y

RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

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


# create nova database
mysql -u root -p$DB_ROOT_PASS <<EOF
DROP DATABASE IF EXISTS cinder;
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO '$CINDER_DBUSER'@'localhost' IDENTIFIED BY '$CINDER_DBPASS';
GRANT ALL PRIVILEGES ON cinder.* TO '$CINDER_DBUSER'@'%' IDENTIFIED BY '$CINDER_DBPASS';
EOF

su -s /bin/sh -c "cinder-manage db sync" cinder

export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

keystone user-delete $CINDER_USER
keystone user-create --name=$CINDER_USER --pass=$CINDER_PASS \
    --email=$CINDER_USER@$CINDER_SERVER
keystone user-role-add --user=$CINDER_USER --tenant=service --role=admin

keystone service-delete cinder
keystone service-create --name=cinder --type=volume \
    --description="OpenStack Block Storage"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ volume / {print $2}') \
    --publicurl=http://$CINDER_SERVER:8776/v1/%\(tenant_id\)s \
    --internalurl=http://$CINDER_SERVER:8776/v1/%\(tenant_id\)s \
    --adminurl=http://$CINDER_SERVER:8776/v1/%\(tenant_id\)s

keystone service-delete cinderv2
keystone service-create --name=cinderv2 --type=volumev2 \
    --description="OpenStack Block Storage v2"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ volumev2 / {print $2}') \
    --publicurl=http://$CINDER_SERVER:8776/v2/%\(tenant_id\)s \
    --internalurl=http://$CINDER_SERVER:8776/v2/%\(tenant_id\)s \
    --adminurl=http://$CINDER_SERVER:8776/v2/%\(tenant_id\)s

service cinder-scheduler restart
service cinder-api restart

# vim: ts=4 sw=4 et tw=79
