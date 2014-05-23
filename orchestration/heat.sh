#!/bin/sh
# test!!!!!!!!!!!!

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


HEAT_DBUSER="heat"
HEAT_DBPASS=`gen_pass`
HEAT_USER="heat"
HEAT_PASS=`gen_pass`
HEAT_SERVER=`hostname -s`

DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

ini_set $stack_conf "heat" "db_username" $HEAT_DBUSER
ini_set $stack_conf "heat" "db_password" $HEAT_DBPASS
ini_set $stack_conf "heat" "host" $HEAT_SERVER
ini_set $stack_conf "heat" "username" $HEAT_USER
ini_set $stack_conf "heat" "password" $HEAT_PASS

apt-get install heat-api heat-api-cfn heat-engine -y

RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

conf_file="/etc/heat/heat.conf"
ini_set $conf_file "database" "connection" \
    "mysql://$HEAT_DBUSER:$HEAT_DBPASS@$DB_SERVER/heat"
ini_set $conf_file "DEFAULT" "auth_strategy" "keystone"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$HEAT_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$HEAT_PASS"
ini_set $conf_file "ec2authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000/v2.0"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"
ini_set $conf_file "DEFAULT" "heat_metadata_server_url" \
    "http://$KEYSTONE_SERVER:8000"
ini_set $conf_file "DEFAULT" "heat_waitcondition_server_url" \
    "http://$KEYSTONE_SERVER:8000/v1/waitcondition"

# create heat database
mysql -u root -p$DB_ROOT_PASS <<EOF
DROP DATABASE IF EXISTS heat;
CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO '$HEAT_DBUSER'@'localhost' IDENTIFIED BY '$HEAT_DBPASS';
GRANT ALL PRIVILEGES ON heat.* TO '$HEAT_DBUSER'@'%' IDENTIFIED BY '$HEAT_DBPASS';
EOF

su -s /bin/sh -c "heat-manage db sync" heat

export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

keystone user-delete $HEAT_USER
keystone user-create --name=$HEAT_USER --pass=$HEAT_PASS \
    --email=$HEAT_USER@$HEAT_SERVER
keystone user-role-add --user=$HEAT_USER --tenant=service --role=admin

keystone service-delete heat
keystone service-create --name=heat --type=orchestration \
      --description="Orchestration"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ orchestration / {print $2}') \
    --publicurl=http://$HEAT_SERVER:8004/v1/%\(tenant_id\)s \
    --internalurl=http://$HEAT_SERVER:8004/v1/%\(tenant_id\)s \
    --adminurl=http://$HEAT_SERVER:8004/v1/%\(tenant_id\)s
keystone service-create --name=heat-cfn --type=cloudformation \
    --description="Orchestration CloudFormation"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ cloudformation / {print $2}') \
    --publicurl=http://$HEAT_SERVER:8000/v1 \
    --internalurl=http://$HEAT_SERVER:8000/v1 \
    --adminurl=http://$HEAT_SERVER:8000/v1

keystone role-create --name heat_stack_user


rm -rf /var/lib/heat/heat.sqlite

service heat-api restart
service heat-api-cfn restart
service heat-engine restart


# vim: ts=4 sw=4 et tw=79
