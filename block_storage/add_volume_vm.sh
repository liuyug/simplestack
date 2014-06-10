#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../admin-openrc.sh


CLOUD_SERVER=$1
VOLUME=$2
SIZE=$3

cinder create --display-name $VOLUME $SIZE

echo -n "Wait volume \"$VOLUME\" ready"
while ! cinder show $VOLUME >/dev/null 2>&1; do
    echo -n "."
done
echo ""

volume_id=`nova volume-list | awk "/ $VOLUME /{print \$2}"`
if [ ! "x$volume_id" = "x" ]; then
    nova volume-attach $CLOUD_SERVER $volume_id
fi
#nova volume-detach $CLOUD_SERVER $volume_id

# vim: ts=4 sw=4 et tw=79
