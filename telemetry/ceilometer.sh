#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

CEILOMETER_DBUSER="ceilometer"
CEILOMETER_DBPASS=`gen_pass`
CEILOMETER_USER="ceilometer"
CEILOMETER_PASS=`gen_pass`
CEILOMETER_SERVER=`hostname -s`
CEILOMETER_TOKEN=`gen_pass`

DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

RABBIT_USER=`ini_get $stack_conf "rabbit" "username"`
RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

ini_set $stack_conf "ceilometer" "db_username" $CEILOMETER_DBUSER
ini_set $stack_conf "ceilometer" "db_password" $CEILOMETER_DBPASS
ini_set $stack_conf "ceilometer" "host" $CEILOMETER_SERVER
ini_set $stack_conf "ceilometer" "username" $CEILOMETER_USER
ini_set $stack_conf "ceilometer" "password" $CEILOMETER_PASS
ini_set $stack_conf "ceilometer" "token" $CEILOMETER_TOKEN

apt-get install ceilometer-api ceilometer-collector ceilometer-agent-central \
    ceilometer-agent-notification ceilometer-alarm-evaluator \
    ceilometer-alarm-notifier python-ceilometerclient -y
apt-get install mongodb-server -y

conf_file="/etc/mongodb.conf"
ini_set $conf_file "#" "bind_ip" "$CEILOMETER_SERVER"

service mongodb restart

echo -n "Wait mongodb ready"
while ! mongo --host $CEILOMETER_SERVER --eval "help" > /dev/null 2>&1; do
    echo -n "."
    sleep 1s
done
echo ""

mongo --host $CEILOMETER_SERVER --eval "
db = db.getSiblingDB(\"ceilometer\");
db.addUser({user: \"$CEILOMETER_USER\",
pwd: \"$CEILOMETER_DBPASS\",
roles: [ 'readWrite', 'dbAdmin' ]})"


conf_file="/etc/ceilometer/ceilometer.conf"
ini_set $conf_file "database" "connection" \
    "mongodb://$CEILOMETER_DBUSER:$CEILOMETER_DBPASS@$CEILOMETER_SERVER:27017/ceilometer"
ini_set $conf_file "publisher" "metering_secret" "$CEILOMETER_TOKEN"
ini_set $conf_file "DEFAULT" "auth_strategy" "keystone"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$CEILOMETER_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$CEILOMETER_PASS"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"
ini_set $conf_file "service_credentials" "os_auth_url" \
    "http://$KEYSTONE_SERVER:5000/v2.0"
ini_set $conf_file "service_credentials" "os_username" "$CEILOMETER_USER"
ini_set $conf_file "service_credentials" "os_tenant_name" "service"
ini_set $conf_file "service_credentials" "os_password" "$CEILOMETER_PASS"

export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

keystone user-delete $CEILOMETER_USER
keystone user-create --name=$CEILOMETER_USER --pass=$CEILOMETER_PASS \
    --email=$CEILOMETER_USER@$CEILOMETER_SERVER
keystone user-role-add --user=$CEILOMETER_USER --tenant=service --role=admin

keystone service-delete ceilometer
keystone service-create --name=ceilometer --type=metering \
    --description="Telemetry"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ metering / {print $2}') \
    --publicurl=http://$CEILOMETER_SERVER:8777 \
    --internalurl=http://$CEILOMETER_SERVER:8777 \
    --adminurl=http://$CEILOMETER_SERVER:8777

service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service ceilometer-alarm-evaluator restart
service ceilometer-alarm-notifier restart

# check
# ceilometer meter-list


# vim: ts=4 sw=4 et tw=79
