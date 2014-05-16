#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

RABBIT_SERVER=`hostname -s`
RABBIT_USER="guest"
RABBIT_PASS=`gen_pass`

ini_set $stack_conf "rabbit" "host" $RABBIT_SERVER
ini_set $stack_conf "rabbit" "username" $RABBIT_USER
ini_set $stack_conf "rabbit" "password" $RABBIT_PASS

apt-get remove rabbitmq-server -y
apt-get install rabbitmq-server -y
rabbitmqctl change_password $RABBIT_USER $RABBIT_PASS

# vim: ts=4 sw=4 et tw=79
