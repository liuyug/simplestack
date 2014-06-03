#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../functions.sh

apt-get install lvm2 -y
# pvcreate /dev/sdb
# vgcreate cinder-volumes /dev/sdb

# /etc/lvm/lvm.conf
# devices {
# ...
# filter = [ "a/sda1/", "a/sdb/", "r/.*/"]
# ...
# }

CINDER_VOLUMES_NAME="cinder-volumes"
CINDER_VOLUMES_FILE="cinder_volumes_file"
if [ ! -f $cur_dir/$CINDER_VOLUMES_FILE ]; then
    truncate -s 1GB $cur_dir/$CINDER_VOLUMES_FILE
fi
CINDER_DEVICE=`losetup -a | grep "$cur_dir/$CINDER_VOLUMES_FILE" | cut -d: -f1`
if [ "x$CINDER_DEVICE" = "x" ]; then
    CINDER_DEVICE=`losetup --show -f $cur_dir/$CINDER_VOLUMES_FILE`
fi
if ! pvs $CINDER_DEVICE; then
    pvcreate $CINDER_DEVICE
fi
if ! vgs $CINDER_VOLUMES_NAME; then
    vgcreate $CINDER_VOLUMES_NAME $CINDER_DEVICE
fi

# vim: ts=4 sw=4 et tw=79
