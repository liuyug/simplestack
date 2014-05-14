#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../functions.sh
pass_file=$cur_dir/../pass.lst

rabbit_userid="guest"
rabbit_password=`gen_pass`

echo "RabbitMQ : $rabbit_userid" | tee -a $pass_file
echo "RabbitMQ : $rabbit_password" | tee -a $pass_file

apt-get install rabbitmq-server -y
rabbitmqctl change_password $rabbit_userid $rabbit_password

# vim: ts=4 sw=4 et tw=79
