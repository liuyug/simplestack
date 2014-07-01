#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


apt-get install neutron-plugin-ml2 neutron-plugin-openvswitch-agent \
    neutron-l3-agent neutron-dhcp-agent -y
major=$(uname -r | cut -d"." -f 1)
minor=$(uname -r | cut -d"." -f 2)
if [[ $major -eq 3 && $minor -lt 11 ]]; then
    apt-get install openvswitch-datapath-dkms -y
fi

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

NEUTRON_USER=`ini_get $stack_conf "neutron" "username"`
NEUTRON_PASS=`ini_get $stack_conf "neutron" "password"`
METADATA_SECRET=`ini_get $stack_conf "neutron" "metadata_secret"`
NEUTRON_NODE_SERVER=`hostname -s`
NEUTRON_EXTERNAL_INTERFACE="eth0"

NOVA_SERVER=`ini_get $stack_conf "nova" "host"`

RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

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

# To configure the Layer-3 (L3) agent
conf_file="/etc/neutron/l3_agent.ini"
ini_set $conf_file "DEFAULT" "interface_driver" \
    "neutron.agent.linux.interface.OVSInterfaceDriver"
ini_set $conf_file "DEFAULT" "use_namespaces" "True"
# to trouble shooting
ini_set $conf_file "DEFAULT" "verbose" "True"

# To configure the DHCP agent
conf_file="/etc/neutron/dhcp_agent.ini"
ini_set $conf_file "DEFAULT" "interface_driver" \
    "neutron.agent.linux.interface.OVSInterfaceDriver"
ini_set $conf_file "DEFAULT" "dhcp_driver" "neutron.agent.linux.dhcp.Dnsmasq"
ini_set $conf_file "DEFAULT" "use_namespaces" "True"
# to trouble shooting
ini_set $conf_file "DEFAULT" "verbose" "True"

# To configure the metadata agent
conf_file="/etc/neutron/metadata_agent.ini"
ini_set $conf_file "DEFAULT" "auth_url" "http://$KEYSTONE_SERVER:5000/v2.0"
ini_set $conf_file "DEFAULT" "auth_region" "regionOne"
ini_set $conf_file "DEFAULT" "admin_tenant_name" "service"
ini_set $conf_file "DEFAULT" "admin_user" "$NEUTRON_USER"
ini_set $conf_file "DEFAULT" "admin_password" "$NEUTRON_PASS"
ini_set $conf_file "DEFAULT" "nova_metadata_ip" "$NOVA_SERVER"
ini_set $conf_file "DEFAULT" "metadata_proxy_shared_secret" "$METADATA_SECRET"
# to trouble shooting
ini_set $conf_file "DEFAULT" "verbose" "True"

# To configure the Modular Layer 2 (ML2) plug-in
conf_file="/etc/neutron/plugins/ml2/ml2_conf.ini"
ini_set $conf_file "ml2" "type_drivers" "local"
ini_set $conf_file "ml2" "tenant_network_types" "local"
ini_set $conf_file "ml2" "mechanism_drivers" "openvswitch"
ini_set $conf_file "ml2_type_gre" "tunnel_id_ranges" "1:1000"
ini_set $conf_file "ovs" "local_ip" "$(get_ip_by_hostname $NEUTRON_NODE_SERVER)"
ini_set $conf_file "ovs" "tunnel_type" "gre"
ini_set $conf_file "ovs" "enable_tunneling" "False"
ini_set $conf_file "securitygroup" "firewall_driver" \
    "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"
ini_set $conf_file "securitygroup" "enable_security_group" "True"

conf_file="/etc/sysctl.conf"
ini_set $conf_file "#" "net.ipv4.ip_forward" "1"
ini_set $conf_file "#" "net.ipv4.conf.all.rp_filter" "0"
ini_set $conf_file "#" "net.ipv4.conf.default.rp_filter" "0"
sysctl -p

# To configure the Open vSwitch (OVS) service
service openvswitch-switch restart
ovs-vsctl del-br br-int
ovs-vsctl add-br br-int
ovs-vsctl del-br br-ex
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $NEUTRON_EXTERNAL_INTERFACE

# move NEUTRON_EXTERNAL_INTERFACE ip to br-ex and set promisc mode
#ips=$(get_ips_by_interface $NEUTRON_EXTERNAL_INTERFACE)
#gateway=$(ip route | awk '/^default /{print $3}')
# for ip in ips; do
#     ip addr del $ip dev $NEUTRON_EXTERNAL_INTERFACE
#     ip addr add $ip dev br-ex
# done
# if ip route | grep default | grep $NEUTRON_EXTERNAL_INTERFACE; then
#     gateway=$(ip route | awk '/^default /{print $3}')
#     ip change '0.0.0.0/0' via $gateway dev br-ex
# fi
# ip link set dev $NEUTRON_EXTERNAL_INTERFACE promisc on
# 
cat <<EOF > br-ex_interface
# append and change in /etc/network/interface
auto br-ex
iface br-ex inet static
address 192.168.203.1
netmask 255.255.255.0
gateway 192.168.203.1
dns-nameserver 8.8.8.8

auto eth0
iface eth0 inet manual
up   ifconfig \$IFACE 0.0.0.0 up
down ifconfig \$IFACE down
EOF

# disable Generic Receive Offload (GRO) to achieve suitable throughput between
# your instances and the external network.
#ethtool -K $NEUTRON_EXTERNAL_INTERFACE gro off

service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart


# vim: ts=4 sw=4 et tw=79
