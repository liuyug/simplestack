#!/bin/sh

# ===========================
# Install OpenStack on Ubuntu
# ===========================

set -e

# Install NTP
# -----------
# To synchronize services across multiple machines, Must install NTP and
# configure additional nodes to synchronize their time from the controller node
# rather than from outside of your LAN

ntp/ntp.sh

# Database
# ---------
# Most OpenStack services require a database to store information. I use MySQL
# database. Must install the MySQL database on the controller node. Must
# install the MySQL Python library on any additional nodes that access MySQL.

database/db.sh 127.0.0.1
database/db_client.sh

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

ubuntu_repo.sh

# Messaging server
# ----------------
# OpenStack uses a message broker to coordinate operations and status
# information among services. The message broker service typically runs on the
# controller node. OpenStack supports several message brokers including
# RabbitMQ, Qpid, and ZeroMQ.

messaging/mq.sh

# Identity Service
# ----------------
# The Identity Service performs the following functions:
#
# + User management. Tracks users and their permissions.
# + Service catalog. Provides a catalog of available services with their API
# endpoints.

keystone/keystone.sh

# vim: ts=4 sw=4 et tw=79
