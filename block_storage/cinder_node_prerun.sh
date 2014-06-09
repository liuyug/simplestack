#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf


apt-get install lvm2 -y
# pvcreate /dev/sdb
# vgcreate cinder-volumes /dev/sdb

# /etc/lvm/lvm.conf
# devices {
# ...
# filter = [ "a/sda1/", "a/sdb/", "r/.*/"]
# ...
# }

CINDER_VOLUMES="cinder-volumes"
CINDER_VOLUMES_FILE="cinder_volumes_file"


ini_set $stack_conf "cinder" "cinder_volumes" "$CINDER_VOLUMES"

if [ ! -f $cur_dir/$CINDER_VOLUMES_FILE ]; then
    truncate -s 10G $cur_dir/$CINDER_VOLUMES_FILE
fi
CINDER_DEVICE=`losetup -a | grep "$cur_dir/$CINDER_VOLUMES_FILE" | cut -d: -f1`
if [ "x$CINDER_DEVICE" = "x" ]; then
    CINDER_DEVICE=`losetup --show -f $cur_dir/$CINDER_VOLUMES_FILE`
fi
if ! pvs $CINDER_DEVICE >/dev/null 2>&1; then
    pvcreate $CINDER_DEVICE
fi
if ! vgs $CINDER_VOLUMES >/dev/null 2>&1; then
    vgcreate $CINDER_VOLUMES $CINDER_DEVICE
fi

# vim: ts=4 sw=4 et tw=79
