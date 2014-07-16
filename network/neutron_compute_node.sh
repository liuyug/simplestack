#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


NEUTRON_USER=`ini_get $stack_conf "neutron" "username"`
NEUTRON_PASS=`ini_get $stack_conf "neutron" "password"`
NEUTRON_SERVER=`ini_get $stack_conf "neutron" "host"`
METADATA_SECRET=`ini_get $stack_conf "neutron" "metadata_secret"`
NOVA_COMPUTE_SERVER=`ini_get $stack_conf "nova" "host_compute"`

KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`

RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

apt-get install neutron-common neutron-plugin-ml2 \
    neutron-plugin-openvswitch-agent -y

major=$(uname -r | cut -d"." -f 1)
minor=$(uname -r | cut -d"." -f 2)
if [[ $major -eq 3 && $minor -lt 11 ]]; then
    apt-get install openvswitch-datapath-dkms -y
fi

conf_file="/etc/neutron/neutron.conf"
# Configure Networking to use the message broker
ini_set $conf_file "DEFAULT" "rpc_backend" "neutron.openstack.common.rpc.impl_kombu"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
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
# Modular Layer 2 (ML2) plug-in and associated services
ini_set $conf_file "DEFAULT" "core_plugin" "ml2"
ini_set $conf_file "DEFAULT" "service_plugins" "router"
ini_set $conf_file "DEFAULT" "allow_overlapping_ips" "True"
# to trouble shooting
ini_set $conf_file "DEFAULT" "verbose" "True"
# Comment out any lines in the [service_providers] section
ini_comment $conf_file "service_providers" ".*"

# To configure the Modular Layer 2 (ML2) plug-in
conf_file="/etc/neutron/plugins/ml2/ml2_conf.ini"
ini_set $conf_file "ml2" "type_drivers" "local"
ini_set $conf_file "ml2" "tenant_network_types" "local"
ini_set $conf_file "ml2" "mechanism_drivers" "openvswitch"
ini_set $conf_file "ml2_type_gre" "tunnel_id_ranges" "1:1000"
ini_set $conf_file "ovs" "integration_bridge" "br-int"
ini_set $conf_file "securitygroup" "firewall_driver" \
    "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"
ini_set $conf_file "securitygroup" "enable_security_group" "True"

conf_file="/etc/nova/nova.conf"
ini_set $conf_file "DEFAULT" "network_api_class" \
        "nova.network.neutronv2.api.API"
ini_set $conf_file "DEFAULT" "neutron_url" "http://$NEUTRON_SERVER:9696"
ini_set $conf_file "DEFAULT" "neutron_auth_strategy" "keystone"
ini_set $conf_file "DEFAULT" "neutron_admin_tenant_name" "service"
ini_set $conf_file "DEFAULT" "neutron_admin_username" "$NEUTRON_USER"
ini_set $conf_file "DEFAULT" "neutron_admin_password" "$NEUTRON_PASS"
ini_set $conf_file "DEFAULT" "neutron_admin_auth_url" \
        "http://$KEYSTONE_SERVER:35357/v2.0"
ini_set $conf_file "DEFAULT" "linuxnet_interface_driver" \
        "nova.network.linux_net.LinuxOVSInterfaceDriver"
# Since Networking includes a firewall service, you must disable the Compute
# firewall service
ini_set $conf_file "DEFAULT" "firewall_driver" \
        "nova.virt.firewall.NoopFirewallDriver"
ini_set $conf_file "DEFAULT" "security_group_api" "neutron"
# To configure the metadata
ini_set $conf_file "DEFAULT" "service_neutron_metadata_proxy" "true"
ini_set $conf_file "DEFAULT" "neutron_metadata_proxy_shared_secret" \
        "$METADATA_SECRET"

conf_file="/etc/sysctl.conf"
ini_set $conf_file "#" "net.ipv4.conf.all.rp_filter" "0"
ini_set $conf_file "#" "net.ipv4.conf.default.rp_filter" "0"
sysctl -p

# To configure the Open vSwitch (OVS) service
service openvswitch-switch restart
ovs-vsctl del-br br-int
ovs-vsctl add-br br-int

# compute service
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-compute restart
service neutron-plugin-openvswitch-agent restart


# vim: ts=4 sw=4 et tw=79
