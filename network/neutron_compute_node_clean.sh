#!/bin/sh

apt-get remove neutron-common neutron-plugin-ml2 \
    neutron-plugin-openvswitch-agent -y

# vim: ts=4 sw=4 et tw=79
