#!/bin/sh

if [ $# -lt 1 ]; then
    echo "$0 <OPENSTACK_PROJECT>"
    exit 1
fi

PROJECTS="
ceilometer
cinder
glance
heat
keystone
neutron
nova
swift
trove
"

case "$1" in
    ceilometer|cinder|glance|heat|keystone|neutron|nova|swift|trove)
        apt-get install python-${1}client
        RETVAL=0
        ;;
    all)
        for project in $PROJECTS; do
            apt-get install python-${project}client
        done
        RETVAL=0
        ;;
    *)
        echo "Error project name: $1"
        RETVAL=1
        ;;
esac
exit $RETVAL

# vim: ts=4 sw=4 et tw=79
