#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
pass_file=$cur_dir/../pass.lst

HOST=`hostname -s`
KEYSTONE_DBUSER="keystone"
KEYSTONE_DBPASS=`gen_pass`
ADMIN_TOKEN=`gen_pass`
DB_ROOT_PASS=`grep "^DB_ROOT_PASS=" "$pass_file" | cut -d"=" -f2`

echo "keystone user: $KEYSTONE_DBUSER" | tee -a $pass_file
echo "keystone pass: $KEYSTONE_DBPASS" | tee -a $pass_file


apt-get remove keystone -y
apt-get install keystone -y

conf_file="/etc/keystone/keystone.conf"
ini_set $conf_file "database" "connection" "mysql://$KEYSTONE_DBUSER:$KEYSTONE_DBPASS@$HOST/keystone"

ini_set $conf_file "DEFAULT" "admin_token" "$ADMIN_TOKEN"
ini_set $conf_file "DEFAULT" "log_dir" "/var/log/keystone"

rm /var/lib/keystone/keystone.db

mysql -u root -p$DB_ROOT_PASS <<EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO '$KEYSTONE_DBUSER'@'localhost' \
      IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO '$KEYSTONE_DBUSER'@'%' \
      IDENTIFIED BY '$KEYSTONE_DBPASS';
EOF

su -s /bin/sh -c "keystone-manage db_sync" keystone

service keystone restart

# remove expired token
#(crontab -l 2>&1 | grep -q token_flush) || \
#    echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/crontabs/root

# vim: ts=4 sw=4 et tw=79
