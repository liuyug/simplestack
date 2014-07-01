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
IMG_FILE="/tmp/ubuntu.img"
IMG_URL="http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img"
IMG_NAME="ubuntu-cloud"
if [ ! -f "$IMG_FILE" ]; then
    wget -O $IMG_FILE $IMG_URL
fi
glance image-delete $IMG_NAME
glance image-create \
    --name $IMG_NAME \
    --disk-format qcow2 \
    --container-format bare \
    --is-public True \
    --progress \
    < "$IMG_FILE"

# check
glance image-list

# vim: ts=4 sw=4 et tw=79
