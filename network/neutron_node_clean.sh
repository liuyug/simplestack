#!/bin/sh

apt-get remove neutron-plugin-ml2 neutron-plugin-openvswitch-agent \
    neutron-l3-agent neutron-dhcp-agent -y

# vim: ts=4 sw=4 et tw=79
