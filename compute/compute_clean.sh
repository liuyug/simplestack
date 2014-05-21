#!/bin/sh

apt-get remove nova-api nova-cert nova-conductor nova-consoleauth \
      nova-novncproxy nova-scheduler python-novaclient -y

# vim: ts=4 sw=4 et tw=79
