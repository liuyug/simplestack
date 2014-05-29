#!/bin/sh
# horizon service

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/../functions.sh
stack_conf=$cur_dir/../stack.conf

KEYSTONE_SERVER=`ini_get $stack_conf "keystone" "host"`

DASHBOARD_SERVER=`hostname -s`

ini_set $stack_conf "dashboard" "host" $DASHBOARD_SERVER

apt-get install apache2 memcached libapache2-mod-wsgi openstack-dashboard
# old and invalid dashboard theme
apt-get remove --purge openstack-dashboard-ubuntu-theme


conf_file="/etc/openstack-dashboard/local_settings.py"
#ini_set $conf_file "#" "ALLOWED_HOSTS" "['localhost', 'my-desktop']"
ini_set $conf_file "#" "OPENSTACK_HOST" "'$DASHBOARD_SERVER'"

# default use memchache
# CACHES = {
# 'default': {
# 'BACKEND' : 'django.core.cache.backends.memcached.MemcachedCache',
# 'LOCATION' : '127.0.0.1:11211'
# }
# }

service apache2 restart
service memcached restart

# check
apt-get install lynx -y
lynx --dump http://$KEYSTONE_SERVER/horizon

# vim: ts=4 sw=4 et tw=79
