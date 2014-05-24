#!/bin/sh
# swift service

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

# generate parameter
SWIFT_USER="swift"
SWIFT_PASS=`gen_pass`
SWIFT_SERVER=`hostname -s`
SWIFT_HASH=`gen_pass`

# external parameter
KEYSTONE_TOKEN=`ini_get $stack_conf "keystone" "admin_token"`
KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`
KEYSTONE_ENDPOINT=`ini_get $stack_conf "keystone" "endpoint"`

ini_set $stack_conf "swift" "host" $SWIFT_SERVER
ini_set $stack_conf "swift" "username" $SWIFT_USER
ini_set $stack_conf "swift" "password" $SWIFT_PASS
ini_set $stack_conf "swift" "hash" $SWIFT_HASH

mkdir -p /etc/swift
conf_file="/etc/swift/swift.conf"
ini_set $conf_file "swift-hash" "swift_hash_path_suffix" "$SWIFT_HASH"


export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT=$KEYSTONE_ENDPOINT

keystone user-delete $SWIFT_USER
keystone user-create --name=$SWIFT_USER --pass=$SWIFT_PASS \
    --email=$SWIFT_USER@$SWIFT_SERVER
keystone user-role-add --user=$SWIFT_USER --tenant=service --role=admin

keystone service-delete swift
keystone service-create --name=swift --type=object-store \
    --description="OpenStack Object Storage"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ object-store / {print $2}') \
    --publicurl=http://$SWIFT_SERVER:8080/v1/AUTH_%\(tenant_id\)s \
    --internalurl=http://$SWIFT_SERVER:8080/v1/AUTH_%\(tenant_id\)s \
    --adminurl=http://$SWIFT_SERVER:8080

apt-get install swift swift-proxy memcached python-keystoneclient \
    python-swiftclient python-webob -y

# /etc/memcached.conf
# -l 127.0.0.1
# -l PROXY_LOCAL_NET_IP
# service memcached restart

# /etc/swift/proxy-server.conf
# [DEFAULT]
# bind_port = 8080
# user = swift
# [pipeline:main]
# pipeline = healthcheck cache authtoken keystoneauth proxy-server
# [app:proxy-server]
# use = egg:swift#proxy
# allow_account_management = true
# account_autocreate = true
# [filter:keystoneauth]
# use = egg:swift#keystoneauth
# operator_roles = Member,admin,swiftoperator
# [filter:authtoken]
# paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
# # Delaying the auth decision is required to support token-less
# # usage for anonymous referrers ('.r:*').
# delay_auth_decision = true
# # cache directory for signing certificate
# signing_dir = /home/swift/keystone-signing
# # auth_* settings refer to the Keystone server
# auth_protocol = http
# auth_host = controller
# auth_port = 35357
# # the service tenant and swift username and password created in Keystone
# admin_tenant_name = service
# admin_user = swift
# admin_password = SWIFT_PASS
# [filter:cache]
# use = egg:swift#memcache
# memcache_servers = PROXY_LOCAL_NET_IP:11211,PROXY_LOCAL_NET_IP:11211
# [filter:catch_errors]
# use = egg:swift#catch_errors
# [filter:healthcheck]
# use = egg:swift#healthcheck

# cd /etc/swift
# swift-ring-builder account.builder create 18 3 1
# swift-ring-builder container.builder create 18 3 1
# swift-ring-builder object.builder create 18 3 1

# swift-ring-builder account.builder add zZONE-STORAGE_LOCAL_NET_IP:6002[RSTORAGE_REPLICATION_NET_IP:6005]/DEVICE 100
# swift-ring-builder container.builder add zZONE-STORAGE_LOCAL_NET_IP_1:6001[RSTORAGE_REPLICATION_NET_IP:6004]/DEVICE 100
# swift-ring-builder object.builder add zZONE-STORAGE_LOCAL_NET_IP_1:6000[RSTORAGE_REPLICATION_NET_IP:6003]/DEVICE 100

# verify
# swift-ring-builder account.builder
# swift-ring-builder container.builder
# swift-ring-builder object.builder

# swift-ring-builder account.builder rebalance
# swift-ring-builder container.builder rebalance
# swift-ring-builder object.builder rebalance
# Copy the account.ring.gz, container.ring.gz, and object.ring.gz files to each
# of the Proxy and Storage nodes in /etc/swift.

#chown -R swift:swift /etc/swift
#service swift-proxy restart


# swift stat
# swift upload myfiles test.txt
# swift upload myfiles test2.txt
# swift download myfiles


# vim: ts=4 sw=4 et tw=79
