#!/bin/sh

set -e

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
pass_file=$cur_dir/../pass.lst

apt-get remove mysql-server-5.5 -y
db_root_pass=`gen_pass`
echo "MySQL root: $db_root_pass" | tee -a $pass_file

echo "mysql-server-5.5 mysql-server/root_password password $db_root_pass" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $db_root_pass" | debconf-set-selections

apt-get install mysql-server -y

db_ip=127.0.0.1
cat <<EOF > ~/.my.cnf
[mysqld]
bind-address=$db_ip
default-storage-engine = innodb
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
EOF

# mysql_install_db
# mysql_secure_installation

# vim: ts=4 sw=4 et tw=79
