
interrupt_cmd="
echo 'Received Ctrl+C to interrupt debug...';
service neutron-server start;
exit 0
"
trap "$interrupt_cmd" INT

service neutron-server stop
/usr/bin/neutron-server --config-file /etc/neutron/neutron.conf --log-file /var/log/neutron/server.log --config-file /etc/neutron/plugins/ml2/ml2_conf.ini $@

# service neutron-server start
