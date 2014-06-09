#!/bin/sh

chown -R swift:swfit /etc/swift

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
