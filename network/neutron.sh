#!/bin/sh

# for controller node

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

# generate parameter
NEUTRON_DBUSER="neutron"
NEUTRON_DBPASS=`gen_pass`
NEUTRON_USER="neutron"
NEUTRON_PASS=`gen_pass`
NEUTRON_SERVER=`hostname -s`
METADATA_SECRET=`gen_pass`

# external parameter
DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

RABBIT_USER=`ini_get $stack_conf "rabbit" "username"`
RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

NOVA_SERVER=`ini_get $stack_conf "nova" "host"`
NOVA_USER=`ini_get $stack_conf "nova" "username"`
NOVA_PASS=`ini_get $stack_conf "nova" "password"`

SERVICE_TENANT_ID=$(keystone tenant-list | awk '/ service / {print $2}')


ini_set $stack_conf "neutron" "db_username" $NEUTRON_DBUSER
ini_set $stack_conf "neutron" "db_password" $NEUTRON_DBPASS
ini_set $stack_conf "neutron" "host" $NEUTRON_SERVER
ini_set $stack_conf "neutron" "username" $NEUTRON_USER
ini_set $stack_conf "neutron" "password" $NEUTRON_PASS
ini_set $stack_conf "neutron" "metadata_secret" $METADATA_SECRET
# external network - 192.168.1.0/24
ini_set $stack_conf "neutron" "floating_ip_start" "192.168.1.2"
ini_set $stack_conf "neutron" "floating_ip_end" "192.168.1.254"
ini_set $stack_conf "neutron" "external_network_gateway" "192.168.1.1"
ini_set $stack_conf "neutron" "external_network_cidr" "192.168.1.0/24"
# tenant network - 10.0.1.0/24
ini_set $stack_conf "neutron" "tenant_network_gateway" "10.0.1.1"
ini_set $stack_conf "neutron" "tenant_network_cidr" "10.0.1.0/28"

# create neutron database
mysql -u root -p$DB_ROOT_PASS <<EOF
DROP DATABASE IF EXISTS neutron;
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO '$NEUTRON_DBUSER'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO '$NEUTRON_DBUSER'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';
EOF

export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

keystone user-delete $NEUTRON_USER
keystone user-create --name=$NEUTRON_USER --pass=$NEUTRON_PASS \
    --email=$NEUTRON_USER@$NEUTRON_SERVER
keystone user-role-add --user=$NEUTRON_USER --tenant=service --role=admin

keystone service-delete neutron
keystone service-create --name=neutron --type=network \
    --description="OpenStack Networking"
keystone endpoint-create \
    --service-id $(keystone service-list | awk '/ network / {print $2}') \
    --publicurl http://$NEUTRON_SERVER:9696 \
    --adminurl http://$NEUTRON_SERVER:9696 \
    --internalurl http://$NEUTRON_SERVER:9696

apt-get install neutron-server neutron-plugin-ml2 -y

conf_file="/etc/neutron/neutron.conf"
# Configure Networking to use the database
ini_set $conf_file "database" "connection" \
    "mysql://$NEUTRON_DBUSER:$NEUTRON_DBPASS@$DB_SERVER/neutron"
# Configure Networking to use the message broker
ini_set $conf_file "DEFAULT" "rpc_backend" "neutron.openstack.common.rpc.impl_kombu"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"
# Configure Networking to use the Identity service for authentication
ini_set $conf_file "DEFAULT" "auth_strategy" "keystone"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$NEUTRON_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$NEUTRON_PASS"
# Configure Networking to notify Compute about network topology changes
ini_set $conf_file "DEFAULT" "notify_nova_on_port_status_changes" "True"
ini_set $conf_file "DEFAULT" "notify_nova_on_port_data_changes" "True"
ini_set $conf_file "DEFAULT" "nova_url" "http://$NOVA_SERVER:8774/v2"
ini_set $conf_file "DEFAULT" "nova_admin_username" "$NOVA_USER"
ini_set $conf_file "DEFAULT" "nova_admin_tenant_id" "$SERVICE_TENANT_ID"
ini_set $conf_file "DEFAULT" "nova_admin_password" "$NOVA_PASS"
ini_set $conf_file "DEFAULT" "nova_admin_auth_url" "http://$KEYSTONE_SERVER:35357/v2.0"
# Modular Layer 2 (ML2) plug-in and associated services
ini_set $conf_file "DEFAULT" "core_plugin" "ml2"
ini_set $conf_file "DEFAULT" "service_plugins" "router"
ini_set $conf_file "DEFAULT" "allow_overlapping_ips" "True"
# to trouble shooting
ini_set $conf_file "DEFAULT" "verbose" "True"
# Comment out any lines in the [service_providers] section
ini_comment $conf_file "service_providers" ".*"

# The ML2 plug-in uses the Open vSwitch (OVS) mechanism (agent) to build the
# virtual networking framework for instances. However, the controller node does
# not need the OVS agent or service because it does not handle instance network
# traffic
conf_file="/etc/neutron/plugins/ml2/ml2_conf.ini"
ini_set $conf_file "ml2" "type_drivers" "local"
ini_set $conf_file "ml2" "tenant_network_types" "local"
ini_set $conf_file "ml2" "mechanism_drivers" "openvswitch"
ini_set $conf_file "ml2_type_gre" "tunnel_id_ranges" "1:1000"
ini_set $conf_file "securitygroup" "firewall_driver" \
    "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"
ini_set $conf_file "securitygroup" "enable_security_group" "True"


service nova-api restart
service nova-scheduler restart
service nova-conductor restart

service neutron-server restart

# vim: ts=4 sw=4 et tw=79
