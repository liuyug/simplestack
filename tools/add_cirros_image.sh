#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../admin-openrc.sh

echo -n "Wait glance service ready"
while ! glance image-list >/dev/null 2>&1; do
    echo -n "."
    sleep 1s
done
echo ""

# upload local file
# "file image_file" to check file format
IMG_FILE="/tmp/cirros.img"
IMG_URL="http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img"
if [ ! -f "$IMG_FILE" ]; then
    wget -O $IMG_FILE $IMG_URL
fi
glance image-delete "cirros-x86_64" 
glance image-create \
    --name "cirros-x86_64" \
    --disk-format qcow2 \
    --container-format bare \
    --is-public True \
    --progress \
    < "$IMG_FILE"

# upload remote file
# glance image-create \
#     --name="cirros-0.3.2-x86_64" \
#     --disk-format=qcow2 \
#     --container-format=bare \
#     --is-public=true \
#     --copy-from http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img

# check
glance image-list

# vim: ts=4 sw=4 et tw=79
