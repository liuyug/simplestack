#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

apt-get remove nova-compute-kvm python-guestfs -y
apt-get install nova-compute-kvm python-guestfs -y

dpkg-statoverride  --update --add root root 0644 /boot/vmlinuz-$(uname -r)

# enable this override for all future kernel updates
cat <<EOF > /etc/kernel/postinst.d/statoverride
#!/bin/sh
version="\$1"
# passing the kernel version is required
[ -z "\${version}" ] && exit 0
dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-\${version}
EOF
chmod +x /etc/kernel/postinst.d/statoverride

DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

NOVA_DBUSER=`ini_get $stack_conf "nova" "db_username"`
NOVA_DBPASS=`ini_get $stack_conf "nova" "db_password"`
NOVA_SERVER=`ini_get $stack_conf "nova" "host"`
NOVA_COMPUTE_SERVER=`hostname -s`
ini_set $stack_conf "nova" "host_compute" $NOVA_COMPUTE_SERVER

GLANCE_SERVER=`ini_get $stack_conf "glance" "host"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

conf_file="/etc/nova/nova.conf"
ini_set $conf_file "database" "connection" \
    "mysql://$NOVA_DBUSER:$NOVA_DBPASS@$DB_SERVER/nova"
ini_set $conf_file "DEFAULT" "rpc_backend" "rabbit"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"
ini_set $conf_file "DEFAULT" "auth_strategy" "keystone"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$NOVA_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$NOVA_PASS"
ini_set $conf_file "DEFAULT" "my_ip" "$NOVA_COMPUTE_SERVER"
ini_set $conf_file "DEFAULT" "vnc_enabled" "True"
ini_set $conf_file "DEFAULT" "vncserver_listen" "0.0.0.0"
ini_set $conf_file "DEFAULT" "vncserver_proxyclient_address" "$NOVA_COMPUTE_SERVER"
ini_set $conf_file "DEFAULT" "novncproxy_base_url" "http://$NOVA_SERVER:6080/vnc_auto.html"
ini_set $conf_file "DEFAULT" "glance_host" "$GLANCE_SERVER"

ret=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $ret -gt 0 ]; then
    echo "Compute node support hardware acceleration VM"
else
    echo "Change "virt_type = qemu" of [libvirt] in /etc/nova/nova-compute.conf"
fi

# /var/log/nova/nova-compute.log
# libvirtError: internal error: no supported architecture for os type 'hvm'
# echo 'kvm_intel' >> /etc/modules
# echo 'kvm_amd' >> /etc/modules

rm -rf /var/lib/nova/nova.sqlite

service nova-compute restart

# vim: ts=4 sw=4 et tw=79
