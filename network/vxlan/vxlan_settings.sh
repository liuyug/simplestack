#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../../functions.sh

# multicast group 239.0.0.0 - 239.255.255.255
MULTICAST=239.1.1.1

# To configure the Modular Layer 2 (ML2) plug-in
conf_file="/etc/neutron/plugins/ml2/ml2_conf.ini"
ini_set $conf_file "ml2" "type_drivers" "vxlan"
ini_set $conf_file "ml2" "tenant_network_types" "vxlan"
ini_set $conf_file "ml2" "mechanism_drivers" "openvswitch"
ini_set $conf_file "ml2_type_vxlan" "vni_ranges" "1:1000"
ini_set $conf_file "ml2_type_vxlan" "vxlan_group" "$MULTICAST"
ini_set $conf_file "ovs" "integration_bridge" "br-int"
ini_set $conf_file "ovs" "tunnel_bridge" "br-tun"
ini_set $conf_file "ovs" "local_ip" "$DATA_INTERFACE_IP"
ini_set $conf_file "ovs" "tunnel_type" "vxlan"
ini_set $conf_file "agent" "tunnel_types" "vxlan"

service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-server restart

# vim: ts=4 sw=4 et tw=79
