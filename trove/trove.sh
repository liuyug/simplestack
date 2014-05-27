#!/bin/sh
# test!!!!!!!!!!!!

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


TROVE_DBUSER="trove"
TROVE_DBPASS=`gen_pass`
TROVE_USER="trove"
TROVE_PASS=`gen_pass`
TROVE_SERVER=`hostname -s`

DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

RABBIT_USER=`ini_get $stack_conf "rabbit" "username"`
RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

NOVA_SERVER=`ini_get $stack_conf "nova" "host"`
CINDER_SERVER=`ini_get $stack_conf "cinder" "host"`
SWIFT_SERVER=`ini_get $stack_conf "swift" "host"`

ini_set $stack_conf "trove" "db_username" $TROVE_DBUSER
ini_set $stack_conf "trove" "db_password" $TROVE_DBPASS
ini_set $stack_conf "trove" "host" $TROVE_SERVER
ini_set $stack_conf "trove" "username" $TROVE_USER
ini_set $stack_conf "trove" "password" $TROVE_PASS

apt-get install python-trove python-troveclient python-glanceclient \
      trove-common trove-api trove-taskmanager -y

conf_file="/etc/trove/trove.conf"
ini_set $conf_file "DEFAULT" "trove_auth_url" "http://$KEYSTONE_SERVER:5000/v2.0"
ini_set $conf_file "DEFAULT" "nova_compute_url" "http://$NOVA_SERVER:8774/v2"
ini_set $conf_file "DEFAULT" "cinder_url" "http://$CINDER_SERVER:8776/v1"
ini_set $conf_file "DEFAULT" "swift_url" "http://$SWIFT_SERVER:8080/v1/AUTH_"
ini_set $conf_file "DEFAULT" "sql_connection" \
    "$TROVE_DBUSER:$TROVE_DBPASS@$DB_SERVER/trove"
ini_set $conf_file "DEFAULT" "notifier_queue_hostname" "$KEYSTONE_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"

conf_file="/etc/trove/trove-taskmanager.conf"
ini_set $conf_file "DEFAULT" "trove_auth_url" "http://$KEYSTONE_SERVER:5000/v2.0"
ini_set $conf_file "DEFAULT" "nova_compute_url" "http://$NOVA_SERVER:8774/v2"
ini_set $conf_file "DEFAULT" "cinder_url" "http://$CINDER_SERVER:8776/v1"
ini_set $conf_file "DEFAULT" "swift_url" "http://$SWIFT_SERVER:8080/v1/AUTH_"
ini_set $conf_file "DEFAULT" "sql_connection" \
    "$TROVE_DBUSER:$TROVE_DBPASS@$DB_SERVER/trove"
ini_set $conf_file "DEFAULT" "notifier_queue_hostname" "$KEYSTONE_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"

conf_file="/etc/trove/trove-conductor.conf"
ini_set $conf_file "DEFAULT" "trove_auth_url" "http://$KEYSTONE_SERVER:5000/v2.0"
ini_set $conf_file "DEFAULT" "nova_compute_url" "http://$NOVA_SERVER:8774/v2"
ini_set $conf_file "DEFAULT" "cinder_url" "http://$CINDER_SERVER:8776/v1"
ini_set $conf_file "DEFAULT" "swift_url" "http://$SWIFT_SERVER:8080/v1/AUTH_"
ini_set $conf_file "DEFAULT" "sql_connection" \
    "$TROVE_DBUSER:$TROVE_DBPASS@$DB_SERVER/trove"
ini_set $conf_file "DEFAULT" "notifier_queue_hostname" "$KEYSTONE_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"


conf_file="/etc/trove/api-paste.ini"
ini_set $conf_file "filter:authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "filter:authtoken" "auth_port" "35357"
ini_set $conf_file "filter:authtoken" "auth_protocol" "http"
ini_set $conf_file "filter:authtoken" "admin_user" "$TROVE_USER"
ini_set $conf_file "filter:authtoken" "admin_password" "$TROVE_PASS"
ini_set $conf_file "filter:authtoken" "admin_token" "$TROVE_TOKEN"
ini_set $conf_file "filter:authtoken" "admin_tenant_name" "service"
ini_set $conf_file "filter:authtoken" "signing_dir" "/var/cache/trove"


conf_file="/etc/trove/trove.conf"
ini_set $conf_file "DEFAULT" "default_datastore" "mysql"
ini_set $conf_file "DEFAULT" "add_addresses" "True"
ini_set $conf_file "DEFAULT" "network_label_regex" "^NETWORK_LABEL$"

conf_file="/etc/trove/trove-taskmanager.conf"
ini_set $conf_file "DEFAULT" "nova_proxy_admin_user" "admin"
ini_set $conf_file "DEFAULT" "nova_proxy_admin_pass" "ADMIN_PASS"
ini_set $conf_file "DEFAULT" "nova_proxy_admin_tenant_name" "service"

conf_file="/etc/trove/trove-guestagent.conf"
ini_set $conf_file "#" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "#" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "#" "rabbit_password" "$RABBIT_PASS"
ini_set $conf_file "#" "nova_proxy_admin_user" "admin"
ini_set $conf_file "#" "nova_proxy_admin_pass" "ADMIN_PASS"
ini_set $conf_file "#" "nova_proxy_admin_tenant_name" "service"
ini_set $conf_file "#" "trove_auth_url" "http://$KEYSTONE_SERVER:35357/v2.0"


mysql -u root -p$DB_ROOT_PASS <<EOF
DROP DATABASE IF EXISTS trove;
CREATE DATABASE trove;
GRANT ALL PRIVILEGES ON trove.* TO '$TROVE_DBUSER'@'localhost' IDENTIFIED BY '$TROVE_DBPASS';
GRANT ALL PRIVILEGES ON trove.* TO '$TROVE_DBUSER'@'%' IDENTIFIED BY '$TROVE_DBPASS';
EOF

su -s /bin/sh -c "trove-manage db_sync" trove
su -s /bin/sh -c "trove-manage datastore_update mysql ''" trove


export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

trove-manage --config-file=/etc/trove/trove.conf datastore_version_update \
    mysql mysql-5.5 mysql glance_image_ID mysql-server-5.5 1

keystone user-delete $TROVE_USER
keystone user-create --name=$TROVE_USER --pass=$TROVE_PASS \
    --email=$TROVE_USER@$TROVE_SERVER
keystone user-role-add --user=$TROVE_USER --tenant=service --role=admin

keystone service-delete trove
keystone service-create --name=trove --type=database \
    --description="OpenStack Database Service"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ trove / {print $2}') \
    --publicurl=http://$TROVE_SERVER:8779/v1.0/%\(tenant_id\)s \
    --internalurl=http://$TROVE_SERVER:8779/v1.0/%\(tenant_id\)s \
    --adminurl=http://$TROVE_SERVER:8779/v1.0/%\(tenant_id\)s

service trove-api restart
service trove-taskmanager restart
service trove-conductor restart

# check
# trove list

# vim: ts=4 sw=4 et tw=79
