#!/bin/sh

# ===========================
# Install OpenStack on Ubuntu
# ===========================

set -e

cur_dir=`dirname  $(readlink -fn $0)`

. $cur_dir/functions.sh

# Install NTP
# -----------
# To synchronize services across multiple machines, Must install NTP and
# configure additional nodes to synchronize their time from the controller node
# rather than from outside of your LAN

apt-get install ntp -y

# Database
# ---------
# Most OpenStack services require a database to store information. I use MySQL
# database. Must install the MySQL database on the controller node. Must
# install the MySQL Python library on any additional nodes that access MySQL.

# in control node
db.sh
# in other node
db_client.sh

# OpenStack packages
# ------------------
# The `Ubuntu Cloud Archive`_ is a special repository that allows you to
# install newer releases of OpenStack on the stable supported version of
# Ubuntu.
#
# .. figure:: https://wiki.ubuntu.com/ServerTeam/CloudArchive?action=AttachFile&do=get&target=plan.png
#
#   Openstack Support Model
#
# .. _`Ubuntu Cloud Archive`: https://wiki.ubuntu.com/ServerTeam/CloudArchive

# Install openstack repository
# .. for 14.04
# .. apt-get install software-properties-common -y
# .. for 12.04
# .. apt-get install python-software-properties -y

apt-get install software-properties-common -y
add-apt-repository cloud-archive:icehouse
apt-get update
apt-get dist-upgrade

# Messaging server
# ----------------
# OpenStack uses a message broker to coordinate operations and status
# information among services. The message broker service typically runs on the
# controller node. OpenStack supports several message brokers including
# RabbitMQ, Qpid, and ZeroMQ.

mq.sh

# vim: ts=4 sw=4 et tw=79
