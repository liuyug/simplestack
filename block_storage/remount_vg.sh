#!/bin/sh

set -o xtrace

cur_dir=`dirname  $(readlink -fn $0)`

CINDER_VOLUMES="cinder-volumes"
CINDER_VOLUMES_FILE="cinder_volumes_file"

CINDER_DEVICE=`losetup -a | grep "$cur_dir/$CINDER_VOLUMES_FILE" | cut -d: -f1`
if [ "x$CINDER_DEVICE" = "x" ]; then
    CINDER_DEVICE=`losetup --show -f $cur_dir/$CINDER_VOLUMES_FILE`
fi

if ! pvs $CINDER_DEVICE; then
    pvcreate $CINDER_DEVICE
fi
if ! vgs $CINDER_VOLUMES; then
    vgcreate $CINDER_VOLUMES $CINDER_DEVICE
fi

# vim: ts=4 sw=4 et tw=79
