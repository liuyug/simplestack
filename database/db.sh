#!/bin/sh

set -e

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
pass_file=$cur_dir/../pass.lst

apt-get remove mysql-server-5.5 -y

DB_ROOT_PASS=`gen_pass`
echo "DB_ROOT_PASS=$DB_ROOT_PASS" | tee -a $pass_file

echo "mysql-server-5.5 mysql-server/root_password password $DB_ROOT_PASS" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $DB_ROOT_PASS" | debconf-set-selections

apt-get install mysql-server -y

db_ip=127.0.0.1
conf_file="/etc/mysql/my.cnf"

ini_set $conf_file "mysqld" "bind-address" $db_ip
ini_set $conf_file "mysqld" "default-storage-engine" "innodb"
ini_set $conf_file "mysqld" "collation-server" "utf8_general_ci"
ini_set $conf_file "mysqld" "init-connect" "'SET NAMES utf8'"
ini_set $conf_file "mysqld" "character-set-server" "utf8"

# mysql_secure_installation

# vim: ts=4 sw=4 et tw=79
