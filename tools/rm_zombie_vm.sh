#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`


if [ $# -lt 1 ];then
    echo "$(basename $0) <name>"
    exit 1
fi
vm_name=$1
vm_uuid=`nova list | awk "/ $vm_name /{print \\\$2}"`
vm_instance=`nova show $vm_name | awk '/:instance_name /{print $4}'`

# remove vm from kvm
virsh undefine $vm_instance
rm -rf "/var/lib/nova/instances/$vm_uuid"

# remove vm from keystone db
mysql -uroot -p$DB_ROOT_PASS << EOF
use nova;
DELETE a FROM nova.security_group_instance_association AS a INNER JOIN
nova.instances AS b ON a.instance_id=b.id where b.uuid='$vm_uuid';
DELETE FROM nova.instance_info_caches WHERE instance_id='$vm_uuid';
DELETE FROM nova.instances WHERE uuid='$vm_uuid';
EOF

# vim: ts=4 sw=4 et tw=79
