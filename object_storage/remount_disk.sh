#!/bin/sh

set -o xtrace

cur_dir=`dirname  $(readlink -fn $0)`

# use file instead device
SWIFT_DISK_FILE="swift_disk_file"
SWIFT_DEVICE=`losetup -a | grep "$cur_dir/$SWIFT_DISK_FILE" | cut -d: -f1`
if [ "x$SWIFT_DEVICE" = "x" ]; then
    SWIFT_DEVICE=`losetup --show -f $cur_dir/$SWIFT_DISK_FILE`
fi

# echo "$SWIFT_DEVICE /srv/node/p1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
mount $SWIFT_DEVICE /srv/node/p1
chown swift:swift /srv/node/p1

# vim: ts=4 sw=4 et tw=79
