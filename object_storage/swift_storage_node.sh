#!/bin/sh
# swift storage node

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

# generate parameter
SWIFT_USER=`ini_get $stack_conf "swift" "username"`
SWIFT_PASS=`ini_get $stack_conf "swift" "password"`
SWIFT_SERVER=`ini_get $stack_conf "swift" "host"`
SWIFT_HASH=`ini_get $stack_conf "swift" "hash"`
PROXY_LOCAL_NET_IP=`get_ip_by_hostname $SWIFT_SERVER`
STORAGE_LOCAL_NET_IP=`get_ip_by_hostname $(hostname -s)`
STORAGE_REPLICATION_NET_IP=$STORAGE_LOCAL_NET_IP

# external parameter
KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`


apt-get install swift swift-account swift-container swift-object xfsprogs -y

# use file instead device
SWIFT_DISK_FILE="swift_disk_file"
truncate -s 1GB $cur_dir/$SWIFT_DISK_FILE
SWIFT_DEVICE=`losetup --show -f $cur_dir/$SWIFT_DISK_FILE`

# fdisk /dev/sdb
# SWIFT_DEVICE=/dev/sdb1

mkfs.xfs $SWIFT_DEVICE
# echo "$SWIFT_DEVICE /srv/node/p1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
mkdir -p /srv/node/p1
mount $SWIFT_DEVICE /srv/node/p1
chown -R swift:swift /srv/node


cat > /etc/rsyncd.conf << EOF
uid = $SWIFT_USER
gid = $SWIFT_USER
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = $STORAGE_LOCAL_NET_IP

[account]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/object.lock
EOF

# /etc/default/rsync:
# RSYNC_ENABLE=true
ini_set "/etc/default/rsync" "#" "RSYNC_ENABLE" "true"

service rsync start

mkdir -p /var/swift/recon
chown -R swift:swift /var/swift/recon

# start service after get all ring file.
# for service in \
#     swift-object \
#     swift-object-replicator \
#     swift-object-updater \
#     swift-object-auditor \
#     swift-container \
#     swift-container-replicator \
#     swift-container-updater \
#     swift-container-auditor \
#     swift-account \
#     swift-account-replicator \
#     swift-account-reaper \
#     swift-account-auditor; do
# service $service start
#     done

# or
swift-init all start

# vim: ts=4 sw=4 et tw=79
