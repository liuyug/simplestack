#!/bin/sh

cur_dir=`dirname  $(readlink -fn $0)`
. $cur_dir/../demo-openrc.sh

nova flavor-create --is-public True id.128  ubuntu.128 128 0 1
nova flavor-create --is-public True id.256  ubuntu.256 256 0 1
nova flavor-create --is-public True id.512  ubuntu.512 512 0 1

# vim: ts=4 sw=4 et tw=79
