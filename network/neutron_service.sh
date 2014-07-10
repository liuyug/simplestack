#!/bin/sh

service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

service neutron-server restart

# vim: ts=4 sw=4 et tw=79
