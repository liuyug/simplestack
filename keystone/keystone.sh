#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
pass_file=$cur_dir/../pass.lst

KEYSTONE_DBUSER="keystone"
KEYSTONE_DBPASS=`gen_pass`
ADMIN_TOKEN=`gen_pass`

DB_SERVER=`ini_get $pass_file "default" "DB_SERVER"`
DB_ROOT_PASS=`ini_get $pass_file "default" "DB_ROOT_PASS"`

echo "KEYSTONE_DBUSER=$KEYSTONE_DBUSER"
echo "KEYSTONE_DBPASS=$KEYSTONE_DBPASS"

ini_set $pass_file "default" "KEYSTONE_DBUSER" $KEYSTONE_DBUSER
ini_set $pass_file "default" "KEYSTONE_DBPASS" $KEYSTONE_DBPASS
ini_set $pass_file "default" "KEYSTONE_TOKEN" $ADMIN_TOKEN
KEYSTONE_SERVER=`hostname -s`
ini_set $pass_file "default" "KEYSTONE_SERVER" $KEYSTONE_SERVER"

echo <<EOF > $cur_dir/../openrc
export OS_SERVICE_TOKEN=$KEYSTONE_TOKEN
export OS_SERVICE_ENDPOINT="http://$KEYSTONE_SERVER:35357/v2.0"
EOF

apt-get remove keystone -y
apt-get install keystone -y

conf_file="/etc/keystone/keystone.conf"
ini_set $conf_file "database" "connection" "mysql://$KEYSTONE_DBUSER:$KEYSTONE_DBPASS@$DB_SERVER/keystone"

ini_set $conf_file "DEFAULT" "admin_token" "$ADMIN_TOKEN"
ini_set $conf_file "DEFAULT" "log_dir" "/var/log/keystone"

rm -rf /var/lib/keystone/keystone.db

# create keystone database
mysql -u root -p$DB_ROOT_PASS <<EOF
DROP DATABASE keystone;
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
