#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../admin-openrc.sh

# upload local file
# "file image_file" to check file format
wget -O /tmp/cirros.img \
    http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img
glance image-create \
    --name "cirros-0.3.2-x86_64" \
    --disk-format qcow2 \
    --container-format bare \
    --is-public True \
    --progress \
    < /tmp/cirros.img
rm -rf /tmp/cirros.img


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
