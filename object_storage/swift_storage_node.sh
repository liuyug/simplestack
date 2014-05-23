#!/bin/sh

apt-get install swift swift-account swift-container swift-object xfsprogs -y


# fdisk /dev/sdb
# mkfs.xfs /dev/sdb1
# echo "/dev/sdb1 /srv/node/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0
# 0" >> /etc/fstab
# mkdir -p /srv/node/sdb1
# mount /srv/node/sdb1
# chown -R swift:swift /srv/node
#  /etc/rsyncd.conf:
#  uid = swift
#  gid = swift
#  log file = /var/log/rsyncd.log
#  pid file = /var/run/rsyncd.pid
#  address = STORAGE_LOCAL_NET_IP
#  address = STORAGE_REPLICATION_NET_IP
#  [account]
#  max connections = 2
#  path = /srv/node/
#  read only = false
#  lock file = /var/lock/account.lock
#  [container]
#  max connections = 2
#  path = /srv/node/
#  read only = false
#  lock file = /var/lock/container.lock
#  [object]
#  max connections = 2
#  path = /srv/node/
#  read only = false
#  lock file = /var/lock/object.lock
#
# /etc/default/rsync:
# RSYNC_ENABLE=true

# service rsync start
# mkdir -p /var/swift/recon
# chown -R swift:swift /var/swift/recon

# start service after get all ring file.
# for service in \
#      swift-object swift-object-replicator swift-object-updater
#swift-object-auditor \
#      swift-container swift-container-replicator swift-container-updater
#swift-container-auditor \
#      swift-account swift-account-replicator swift-account-reaper
#swift-account-auditor; do \
#          service $service start; done
# or
# swift-init all start

# vim: ts=4 sw=4 et tw=79
