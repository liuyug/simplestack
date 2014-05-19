#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

KEYSTONE_DBUSER="keystone"
KEYSTONE_DBPASS=`gen_pass`
KEYSTONE_SERVER=`hostname -s`
ADMIN_TOKEN=`gen_pass`

DB_SERVER=`ini_get $stack_conf "database" "host"`
DB_ROOT_PASS=`ini_get $stack_conf "database" "password"`

ini_set $stack_conf "keystone" "db_username" $KEYSTONE_DBUSER
ini_set $stack_conf "keystone" "db_password" $KEYSTONE_DBPASS
ini_set $stack_conf "keystone" "admin_token" $ADMIN_TOKEN
ini_set $stack_conf "keystone" "host" "$KEYSTONE_SERVER"
ini_set $stack_conf "keystone" "endpoint" "http://$KEYSTONE_SERVER:35357/v2.0"

apt-get remove keystone -y
apt-get install keystone -y

conf_file="/etc/keystone/keystone.conf"
ini_set $conf_file "database" "connection" "mysql://$KEYSTONE_DBUSER:$KEYSTONE_DBPASS@$DB_SERVER/keystone"
ini_set $conf_file "DEFAULT" "admin_token" "$ADMIN_TOKEN"
ini_set $conf_file "DEFAULT" "log_dir" "/var/log/keystone"

rm -rf /var/lib/keystone/keystone.db

# create keystone database
mysql -u root -p$DB_ROOT_PASS <<EOF
DROP DATABASE IF EXISTS keystone;
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO '$KEYSTONE_DBUSER'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO '$KEYSTONE_DBUSER'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
EOF

# create keystone tables
su -s /bin/sh -c "keystone-manage db_sync" keystone

service keystone restart

# remove expired token
#(crontab -l 2>&1 | grep -q token_flush) || \
#    echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/crontabs/root

# vim: ts=4 sw=4 et tw=79
