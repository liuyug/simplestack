#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../../functions.sh


# To configure the Modular Layer 2 (ML2) plug-in
conf_file="/etc/neutron/plugins/ml2/ml2_conf.ini"
ini_set $conf_file "ml2" "type_drivers" "vlan"
ini_set $conf_file "ml2" "tenant_network_types" "vlan"
ini_set $conf_file "ml2" "mechanism_drivers" "openvswitch"
ini_set $conf_file "ml2_type_vlan" "network_vlan_ranges" "phydemo:1:4094"
ini_set $conf_file "ovs" "bridge_mappings" "phydemo:br-data"
ini_set $conf_file "ovs" "integration_bridge" "br-int"

service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-server restart

# vim: ts=4 sw=4 et tw=79
