#!/bin/sh
# mysql db

set -e

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

DB_ROOT_PASS=`gen_pass`
ini_set $stack_conf "database" "username" "root"
ini_set $stack_conf "database" "password" $DB_ROOT_PASS

DB_SERVER=`hostname -s`
ini_set $stack_conf "database" "host" $DB_SERVER

apt-get remove --purge mysql-server mysql-common -y

echo "mysql-server-5.5 mysql-server/root_password password $DB_ROOT_PASS" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $DB_ROOT_PASS" | debconf-set-selections

apt-get install mysql-server mysql-common -y

db_conf_file="/etc/mysql/my.cnf"
ini_set $db_conf_file "mysqld" "bind-address" `get_ip_by_hostname $DB_SERVER`
ini_set $db_conf_file "mysqld" "default-storage-engine" "innodb"
ini_set $db_conf_file "mysqld" "collation-server" "utf8_general_ci"
ini_set $db_conf_file "mysqld" "init-connect" "\"SET NAMES utf8\""
ini_set $db_conf_file "mysqld" "character-set-server" "utf8"

# mysql_secure_installation

service mysql restart

# vim: ts=4 sw=4 et tw=79
