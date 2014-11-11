#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../../functions.sh

DATA_INTERFACE="eth0"
DATA_INTERFACE_IP=$(get_ips_by_interface $DATA_INTERFACE)

# To configure the Modular Layer 2 (ML2) plug-in
conf_file="/etc/neutron/plugins/ml2/ml2_conf.ini"
ini_set $conf_file "ml2" "type_drivers" "gre"
ini_set $conf_file "ml2" "tenant_network_types" "gre"
ini_set $conf_file "ml2" "mechanism_drivers" "openvswitch"
ini_set $conf_file "ml2_type_gre" "tunnel_id_ranges" "1:1000"
ini_set $conf_file "ovs" "integration_bridge" "br-int"
ini_set $conf_file "ovs" "tunnel_bridge" "br-tun"
ini_set $conf_file "ovs" "local_ip" "$DATA_INTERFACE_IP"
ini_set $conf_file "ovs" "tunnel_type" "gre"
ini_set $conf_file "agent" "tunnel_types" "gre"

service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-server restart

# vim: ts=4 sw=4 et tw=79
