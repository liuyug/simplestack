#!/bin/sh

set -e

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/functions.sh

apt-get remove mysql-server-5.5 -y
db_root_pass=`gen_pass`
echo "MySQL root: $db_root_pass" | tee -a pass.lst

echo "mysql-server-5.5 mysql-server/root_password password $db_root_pass" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $db_root_pass" | debconf-set-selections
apt-get install python-mysqldb mysql-server -y

#db_ip=127.0.0.1
#sed -i -r "/^(bind-address *=).*$/\1$db_ip/g"

# add items in my.cnf
# [mysqld]
# default-storage-engine = innodb
# collation-server = utf8_general_ci
# init-connect = 'SET NAMES utf8'
# character-set-server = utf8

# mysql_install_db
# mysql_secure_installation

# vim: ts=4 sw=4 et tw=79
