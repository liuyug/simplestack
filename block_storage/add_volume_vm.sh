#!/bin/sh

. $cur_dir/../admin-openrc.sh


VOLUME=volume_01
CLOUD_SERVER=ubuntu256_01

cinder create --display-name $VOLUME 1
cinder list
volume_id=`nova volume-list | awk "/ $VOLUME /{print \$2}"`
nova volume-attach $CLOUD_SERVER $volume_id
#nova volume-detach $CLOUD_SERVER $volume_id

# vim: ts=4 sw=4 et tw=79
