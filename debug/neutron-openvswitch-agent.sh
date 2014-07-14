
interrupt_cmd="
echo 'Received Ctrl+C to interrupt debug...';
service neutron-plugin-openvswitch-agent start
exit 0
"
trap "$interrupt_cmd" INT

service neutron-plugin-openvswitch-agent stop

/usr/bin/neutron-openvswitch-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini --log-file=/var/log/neutron/openvswitch-agent.log $@

# service neutron-plugin-openvswitch-agent start
