#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

# generate parameter
PRIVATE_INTERFACE_NAME="eth0"
# for single network interface card
PUBLIC_INTERFACE_NAME="br100"
BRIDGE_NAME="br100"
NETWORK_SERVER=`hostname -s`

# for private interface use promiscuous mode to recived all packets
# iface $private_interface inet manual
# up ifconfig $IFACE 0.0.0.0 up
# up ifconfig $IFACE promisc

ini_set $stack_conf "nova-network" "public_interface_name" "$PUBLIC_INTERFACE_NAME"
ini_set $stack_conf "nova-network" "private_interface_name" "$PRIVATE_INTERFACE_NAME"
ini_set $stack_conf "nova-network" "bridge_name" "$BRIDGE_NAME"

apt-get install nova-network -y

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
# will add flat_interface and VM interface
ini_set $conf_file "DEFAULT" "flat_network_bridge" "$BRIDGE_NAME"
# internal interface, private network
ini_set $conf_file "DEFAULT" "flat_interface" "$PRIVATE_INTERFACE_NAME"
# public interface for internet.
ini_set $conf_file "DEFAULT" "public_interface" "$PUBLIC_INTERFACE_NAME"
ini_set $conf_file "DEFAULT" "metadata-host" "$(get_ip_by_hostname $NETWORK_SERVER)"

# permit ip forward
conf_file="/etc/sysctl.conf"
ini_set $conf_file "#" "net.ipv4.ip_forward" "1"
ini_set $conf_file "#" "net.ipv4.conf.all.rp_filter" "0"
ini_set $conf_file "#" "net.ipv4.conf.default.rp_filter" "0"
sysctl -p


service nova-api restart
service nova-scheduler restart
service nova-conductor restart

service nova-network restart

. $cur_dir/../admin-openrc.sh

echo -n "Wait nova service ready"
while ! nova net-list >/dev/null 2>&1; do
    echo -n "."
    sleep 1s
done
echo ""

# add demo-net network
NETWORK_CIDR="10.0.1.0/24"

net_id=`nova net-list | awk '/ private / { printf $2}'`
if [ ! "x$net_id" = "x" ]; then
    nova net-delete $net_id
fi
# nova only identify "public" and "private"
nova network-create private --bridge $BRIDGE_NAME --multi-host T \
    --fixed-range-v4 "$NETWORK_CIDR"

# permit icmp
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
# permit ssh
nova  secgroup-add-rule default tcp 22 22 0.0.0.0/0
# permit vm access external network
# iptables -t nat -A POSTROUTING -o br100 -j MASQUERADE
# iptables -t nat -I POSTROUTING 1 -s 10.0.1.0/24 -o br100 -j MASQUERADE

# check
# nova net-list
# nova secgroup-list

# vim: ts=4 sw=4 et tw=79
