#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

# generate parameter
PUBLIC_INTERFACE_NAME=`ini_get $stack_conf "nova-network" "public_interface_name"`
PRIVATE_INTERFACE_NAME=`ini_get $stack_conf "nova-network" "private_interface_name"`
BRIDGE_NAME=`ini_get $stack_conf "nova-network" "bridge_name"`
NETWORK_SERVER=`hostname -s`

apt-get install nova-network -y
# only for multi-host
apt-get install nova-api-metadata -y

conf_file="/etc/nova/nova.conf"
ini_set $conf_file "DEFAULT" "network_api_class" "nova.network.api.API"
ini_set $conf_file "DEFAULT" "security_group_api" "nova"
ini_set $conf_file "DEFAULT" "firewall_driver" \
    "nova.virt.libvirt.firewall.IptablesFirewallDriver"
ini_set $conf_file "DEFAULT" "network_manager" \
    "nova.network.manager.FlatDHCPManager"
ini_set $conf_file "DEFAULT" "network_size" "254"
ini_set $conf_file "DEFAULT" "allow_same_net_traffic" "False"
ini_set $conf_file "DEFAULT" "multi_host" "True"
ini_set $conf_file "DEFAULT" "send_arp_for_ha" "True"
ini_set $conf_file "DEFAULT" "share_dhcp_address" "True"
ini_set $conf_file "DEFAULT" "force_dhcp_release" "True"
ini_set $conf_file "DEFAULT" "flat_network_bridge" "$BRIDGE_NAME"
ini_set $conf_file "DEFAULT" "flat_interface" "$PRIVATE_INTERFACE_NAME"
ini_set $conf_file "DEFAULT" "public_interface" "$PUBLIC_INTERFACE_NAME"
ini_set $conf_file "DEFAULT" "metadata-host" "$(get_ip_by_hostname $NETWORK_SERVER)"

conf_file="/etc/sysctl.conf"
ini_set $conf_file "#" "net.ipv4.ip_forward" "1"
ini_set $conf_file "#" "net.ipv4.conf.all.rp_filter" "0"
ini_set $conf_file "#" "net.ipv4.conf.default.rp_filter" "0"
sysctl -p


service nova-network restart
service nova-api-metadata restart

# vim: ts=4 sw=4 et tw=79
