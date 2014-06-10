#!/bin/sh

# backup configuration
for i in keystone glance nova cinder neutron openstack-dashboard; do
    mkdir $i-havana
done
for i in keystone glance nova cinder neutron openstack-dashboard; do
    cp -r /etc/$i/* $i-havana/
done

# backup database
mysqldump -u root -p --opt --add-drop-database --all-databases \
    > havana-db-backup.sql
# restore database
# mysql -u root -p < grizzly-db-backup.sql

# vim: ts=4 sw=4 et tw=79
