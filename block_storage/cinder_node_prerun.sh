#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`


apt-get install lvm2 -y
# pvcreate /dev/sdb
# vgcreate cinder-volumes /dev/sdb

# /etc/lvm/lvm.conf
# devices {
# ...
# filter = [ "a/sda1/", "a/sdb/", "r/.*/"]
# ...
# }
CINDER_VOLUMES="cinder_volumes_file"
dd if=/dev/zero of=$cur_dir/$CINDER_VOLUMES bs=1G count=10
losetup -f $cur_dir/$CINDER_VOLUMES
CINDER_DEVICE=`losetup -j $cur_dir/$CINDER_VOLUMES | cut -d":" -f1`
pvcreate $CINDER_DEVICE
vgcreate cinder-volumes $CINDER_DEVICE

# vim: ts=4 sw=4 et tw=79
