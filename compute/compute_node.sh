#!/bin/sh
# nova compute node

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

# generate parameter
NOVA_COMPUTE_SERVER=`hostname -s`

# external parameter
DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

NOVA_DBUSER=`ini_get $stack_conf "nova" "db_username"`
NOVA_DBPASS=`ini_get $stack_conf "nova" "db_password"`

NOVA_USER=`ini_get $stack_conf "nova" "username"`
NOVA_PASS=`ini_get $stack_conf "nova" "password"`
NOVA_SERVER=`ini_get $stack_conf "nova" "host"`

GLANCE_SERVER=`ini_get $stack_conf "glance" "host"`

KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

RABBIT_USER=`ini_get $stack_conf "rabbit" "username"`
RABBIT_PASS=`ini_get $stack_conf "rabbit" "password"`
RABBIT_SERVER=`ini_get $stack_conf "rabbit" "host"`

ini_set $stack_conf "nova" "host_compute" $NOVA_COMPUTE_SERVER

# install db client
apt-get install python-mysqldb python-novaclient -y
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

conf_file="/etc/nova/nova.conf"
ini_set $conf_file "database" "connection" \
    "mysql://$NOVA_DBUSER:$NOVA_DBPASS@$DB_SERVER/nova"
ini_set $conf_file "DEFAULT" "rpc_backend" "rabbit"
ini_set $conf_file "DEFAULT" "rabbit_host" "$RABBIT_SERVER"
ini_set $conf_file "DEFAULT" "rabbit_userid" "$RABBIT_USER"
ini_set $conf_file "DEFAULT" "rabbit_password" "$RABBIT_PASS"
ini_set $conf_file "DEFAULT" "auth_strategy" "keystone"
ini_set $conf_file "keystone_authtoken" "auth_uri" "http://$KEYSTONE_SERVER:5000"
ini_set $conf_file "keystone_authtoken" "auth_host" "$KEYSTONE_SERVER"
ini_set $conf_file "keystone_authtoken" "auth_port" "35357"
ini_set $conf_file "keystone_authtoken" "auth_protocol" "http"
ini_set $conf_file "keystone_authtoken" "admin_tenant_name" "service"
ini_set $conf_file "keystone_authtoken" "admin_user" "$NOVA_USER"
ini_set $conf_file "keystone_authtoken" "admin_password" "$NOVA_PASS"
ini_set $conf_file "DEFAULT" "my_ip" "$(get_ip_by_hostname $NOVA_COMPUTE_SERVER)"
ini_set $conf_file "DEFAULT" "vnc_enabled" "True"
ini_set $conf_file "DEFAULT" "vncserver_listen" "$NOVA_COMPUTE_SERVER"
ini_set $conf_file "DEFAULT" "vncserver_proxyclient_address" "$NOVA_COMPUTE_SERVER"
ini_set $conf_file "DEFAULT" "novncproxy_base_url" "http://$NOVA_SERVER:6080/vnc_auto.html"
ini_set $conf_file "DEFAULT" "glance_host" "$GLANCE_SERVER"
# Fix: Virtual Interface creation failed
ini_set $conf_file "DEFAULT" "vif_plugging_timeout" "0"
ini_set $conf_file "DEFAULT" "vif_plugging_is_fatal" "False"

conf_file="/etc/nova/nova-compute.conf"
ret=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $ret -gt 0 ]; then
    echo "Support hardware acceleration VM. virt_type is \"kvm\"."
    kvm-ok
    ini_set $conf_file "libvirt" "virt_type" "kvm"
else
    echo "virt_type is \"qemu\"."
    ini_set $conf_file "libvirt" "virt_type" "qemu"
fi

# /var/log/nova/nova-compute.log
# libvirtError: internal error: no supported architecture for os type 'hvm'
# echo 'kvm_intel' >> /etc/modules
# echo 'kvm_amd' >> /etc/modules

rm -rf /var/lib/nova/nova.sqlite

service nova-compute restart

#cirros image user/password: cirros:cubswin:)
#nova boot  --key-name default --flavor m1.tiny --image cirros-0.3.2-x86_64 cirros
#nova ssh cirros@cirros
#nova boot --flavor m256 --image ubuntu-cloud --key-name default ubuntu256_01
#nova ssh ubuntu@ubuntu256_01
#nova boot --flavor m256 --image centos6.5 --key-name default centos256_01
#nova ssh cloud-user@centos256_01

# vim: ts=4 sw=4 et tw=79
