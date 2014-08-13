#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


# To configure the Modular Layer 2 (ML2) plug-in
conf_file="/etc/neutron/plugins/ml2/ml2_conf.ini"
ini_set $conf_file "ml2" "type_drivers" "flat"
ini_set $conf_file "ml2" "tenant_network_types" "flat"
ini_set $conf_file "ml2" "mechanism_drivers" "openvswitch"
ini_set $conf_file "ml2_type_flat" "flat_networks" "phydemo"
ini_set $conf_file "ovs" "bridge_mappings" "phydemo:br-data"
ini_set $conf_file "ovs" "integration_bridge" "br-int"

conf_file="/etc/neutron/dhcp_agent.ini"
ini_set $conf_file "DEFAULT" "enable_isolated_metadata" "True"

service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-server restart

# vim: ts=4 sw=4 et tw=79
