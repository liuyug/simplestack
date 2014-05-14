#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../functions.sh
pass_file=$cur_dir/../pass.lst

RABBIT_USER="guest"
RABBIT_PASS=`gen_pass`

echo "RABBIT_USER=$RABBIT_USER"
echo "RABBIT_PASS=$RABBIT_PASS"
ini_set $pass_file "default" "RABBIT_USER" $RABBIT_USER
ini_set $pass_file "default" "RABBIT_PASS" $RABBIT_PASS

apt-get install rabbitmq-server -y
rabbitmqctl change_password $RABBIT_USER $RABBIT_PASS

# vim: ts=4 sw=4 et tw=79
