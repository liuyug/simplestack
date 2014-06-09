#!/bin/sh
# nova service.

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

# generate parameter
NOVA_DBUSER="nova"
NOVA_DBPASS=`gen_pass`
NOVA_USER="nova"
NOVA_PASS=`gen_pass`
NOVA_SERVER=`hostname -s`
NOVA_COMPUTE_SERVER=$NOVA_SERVER

# external parameter
DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

RABBIT_USER=`ini_get $stack_conf "rabbit" "username"`
RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

ini_set $stack_conf "nova" "db_username" $NOVA_DBUSER
ini_set $stack_conf "nova" "db_password" $NOVA_DBPASS
ini_set $stack_conf "nova" "host" $NOVA_SERVER
ini_set $stack_conf "nova" "username" $NOVA_USER
ini_set $stack_conf "nova" "password" $NOVA_PASS
ini_set $stack_conf "nova" "host_compute" $NOVA_COMPUTE_SERVER

# install db client
apt-get install python-mysqldb -y
apt-get install nova-api nova-cert nova-conductor nova-consoleauth \
      nova-novncproxy nova-scheduler python-novaclient -y


conf_file="/etc/nova/nova.conf"
ini_set $conf_file "database" "connection" \
    "mysql://$NOVA_DBUSER:$NOVA_DBPASS@$DB_SERVER/nova"
ini_set $conf_file "DEFAULT" "rpc_backend" "rabbit"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"
ini_set $conf_file "DEFAULT" "auth_strategy" "keystone"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$NOVA_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$NOVA_PASS"
ini_set $conf_file "DEFAULT" "my_ip" "$(get_ip_by_hostname $NOVA_COMPUTE_SERVER)"
# The compute host specifies the address that the proxy should use to connect
# through the nova.conf file option, vncserver_proxyclient_address. In this
# way, the VNC proxy works as a bridge between the public network and private
# host network.
ini_set $conf_file "DEFAULT" "vncserver_listen" "$NOVA_COMPUTE_SERVER"
ini_set $conf_file "DEFAULT" "vncserver_proxyclient_address" "$NOVA_COMPUTE_SERVER"


rm -rf /var/lib/nova/nova.sqlite

# create nova database
mysql -u root -p$DB_ROOT_PASS <<EOF
DROP DATABASE IF EXISTS nova;
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO '$NOVA_DBUSER'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO '$NOVA_DBUSER'@'%' IDENTIFIED BY '$NOVA_DBPASS';
EOF

su -s /bin/sh -c "nova-manage db sync" nova

export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

# create nova user in keystone
keystone user-delete $NOVA_USER
keystone user-create --name=$NOVA_USER --pass=$NOVA_PASS \
    --email=$NOVA_USER@$NOVA_SERVER
keystone user-role-add --user=$NOVA_USER --tenant=service --role=admin

# register service
keystone service-delete nova
keystone service-create --name=nova --type=compute \
    --description="OpenStack Compute"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ compute / {print $2}') \
    --publicurl=http://$NOVA_SERVER:8774/v2/%\(tenant_id\)s \
    --internalurl=http://$NOVA_SERVER:8774/v2/%\(tenant_id\)s \
    --adminurl=http://$NOVA_SERVER:8774/v2/%\(tenant_id\)s

# restart service
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

# check nova
# nova image-list

# check directory permission
ls -l /var/lib/nova

# vim: ts=4 sw=4 et tw=79
