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

apt-get install swift swift-proxy memcached python-keystoneclient \
    python-swiftclient python-webob -y


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

# in all node
mkdir -p /etc/swift
cat > /etc/swift/swift.conf <<EOF
[swift-hash]
swift_hash_path_suffix = $SWIFT_HASH
EOF

# in proxy node
# conf_file="/etc/memcached.conf"
# ini_set $conf_file "#" "-l" "$SWIFT_SERVER"
service memcached restart

# mkdir -p /var/cache/swift/keystone-signing
# chown -R swift:swift /var/cache/swift/keystone-signing

cat > /etc/swift/proxy-server.conf <<EOF
[DEFAULT]
bind_port = 8080
user = $SWIFT_USER

[pipeline:main]
pipeline = healthcheck cache authtoken keystoneauth proxy-server

[app:proxy-server]
use = egg:swift#proxy
allow_account_management = true
account_autocreate = true

[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = Member,admin,swiftoperator

[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
# Delaying the auth decision is required to support token-less
# usage for anonymous referrers ('.r:*').
delay_auth_decision = true
# cache directory for signing certificate
signing_dir = /var/cache/swift/keystone-signing
# auth_* settings refer to the Keystone server
auth_protocol = http
auth_host = $KEYSTONE_SERVER
auth_uri = http://$KEYSTONE_SERVER:5000
auth_port = 35357
# the service tenant and swift username and password created in Keystone
admin_tenant_name = service
admin_user = $SWIFT_USER
admin_password = $SWIFT_PASS

[filter:cache]
use = egg:swift#memcache
memcache_servers = $SWIFT_SERVER:11211

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:healthcheck]
use = egg:swift#healthcheck
EOF

cd /etc/swift
rm -rf account.builder container.builder object.builder

swift-ring-builder account.builder create 18 3 1
swift-ring-builder container.builder create 18 3 1
swift-ring-builder object.builder create 18 3 1


# vim: ts=4 sw=4 et tw=79
