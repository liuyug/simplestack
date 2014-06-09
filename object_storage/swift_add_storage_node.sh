#!/bin/sh
# swift service

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh

if [ "$1" = "-h" ];then
    echo "$(basename $0) <storage local net ip> [storage replication net ip]"
    exit 1
fi

if [ "x$1" = "x" ]; then
    STORAGE_LOCAL_NET_IP=`get_ip_by_hostname $(hostname -s)`
else
    STORAGE_LOCAL_NET_IP=$1
fi

if [ "x$2" = "x" ]; then
    STORAGE_REPLICATION_NET_IP=""
else
    STORAGE_REPLICATION_NET_IP=$2
fi

DEVICE=p1
ZONE=1

cd /etc/swift

# add storage node entries
if [ "x$STORAGE_REPLICATION_NET_IP" = "x" ]; then
    swift-ring-builder account.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6002/$DEVICE 100
    swift-ring-builder container.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6001/$DEVICE 100
    swift-ring-builder object.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6000/$DEVICE 100
else
    swift-ring-builder account.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6002[R$STORAGE_REPLICATION_NET_IP:6005]/$DEVICE 100
    swift-ring-builder container.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6001[R$STORAGE_REPLICATION_NET_IP:6004]/$DEVICE 100
    swift-ring-builder object.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6000[R$STORAGE_REPLICATION_NET_IP:6003]/$DEVICE 100
fi

# verify
swift-ring-builder account.builder
swift-ring-builder container.builder
swift-ring-builder object.builder


# vim: ts=4 sw=4 et tw=79
