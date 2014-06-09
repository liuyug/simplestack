#!/bin/sh
# swift service

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

cd /etc/swift

# verify
swift-ring-builder account.builder
swift-ring-builder container.builder
swift-ring-builder object.builder

swift-ring-builder account.builder rebalance
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder rebalance

chown -R swift:swift /etc/swift

echo "Copy the account.ring.gz, container.ring.gz, and object.ring.gz files \
to each of the Proxy and Storage nodes in /etc/swift."
echo "Example: scp *.gz x.x.x.x:/etc/swift"

service swift-proxy restart

# swift stat
# swift upload myfiles test.txt
# swift upload myfiles test2.txt
# swift download myfiles


# vim: ts=4 sw=4 et tw=79
