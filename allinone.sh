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
#
# rabbitmq port: 53132

messaging/mq.sh

# Identity Service
# ----------------
# The Identity Service performs the following functions:
#
# + User management. Tracks users and their permissions.
# + Service catalog. Provides a catalog of available services with their API
# endpoints.
#
# auth uri ports: 5000, auth port:35357

keystone/keystone.sh
keystone/configure.sh

# Image Service
# -------------
# The OpenStack Image Service enables users to discover, register, and retrieve
# virtual machine images. Also known as the glance project, the Image Service
# offers a REST API that enables you to query virtual machine image metadata
# and retrieve an actual image. You can store virtual machine images made
# available through the Image Service in a variety of locations from simple
# file systems to object-storage systems like OpenStack Object Storage.
#
# + glance-api
#
#   Accepts Image API calls for image discovery, retrieval, and storage.
#
# + glance-registry
#
#   Stores, processes, and retrieves metadata about images. Metadata includes
#   items such as size and type.
#
# glance-api port: 6794
# glance-registry port: 6784

glance/glance.sh
glance/configure.sh

# Compute service
# ---------------
# The Compute service is a cloud computing fabric controller, which is the main
# part of an IaaS system. Use it to host and manage cloud computing systems.
# The main modules are implemented in Python.
#
# The Compute service is made up of the following functional areas and their
# underlying components:
#
# + API
#
#   - nova-api service.
#
#     Accepts and responds to end user compute API calls.
#
#   - nova-api-metadata service.
#
#     Accepts metadata requests from instances. The nova-api-metadata service
#     is generally only used when you run in multi-host mode with nova-network
#     installations.
#
# + Compute core
#
#   - nova-compute process.
#
#     A worker daemon that creates and terminates virtual machine instances
#     through hypervisor APIs.
#
#   - nova-scheduler process.
#
#     Takes a virtual machine instance request from the queue and determines on
#     which compute server host it should run.
#
#   - nova-conductor module.
#
#     Mediates interactions between nova-compute and the database. Aims to
#     eliminate direct accesses to the cloud database made by nova-compute. The
#     nova-conductor module scales horizontally. However, do not deploy it on
#     any nodes where nova-compute runs.
#
# + Networking for VMs
#
#   - nova-network worker daemon.
#
#     Similar to nova-compute, it accepts networking tasks from the queue and
#     performs tasks to manipulate the network, such as setting up bridging
#     interfaces or changing iptables rules. This functionality is being
#     migrated to OpenStack Networking, which is a separate OpenStack service.
#
#   - nova-dhcpbridge script.
#
#     Tracks IP address leases and records them in the database by using the
#     dnsmasq dhcp-script facility. This functionality is being migrated to
#     OpenStack Networking. OpenStack Networking provides a different script.
#
# + Console interface
#
#   - nova-consoleauth daemon.
#
#     Authorizes tokens for users that console proxies provide. This service
#     must be running for console proxies to work.
#
#   - nova-novncproxy daemon.
#
#     Provides a proxy for accessing running instances through a VNC
#     connection. Supports browser-based novnc clients.
#
#   - nova-xvpnvncproxy daemon.
#
#     A proxy for accessing running instances through a VNC connection.
#     Supports a Java client specifically designed for OpenStack.
#
#   - nova-cert daemon.
#
#     Manages x509 certificates.
#
# + Image management (EC2 scenario)
#
#   - nova-objectstore daemon.
#
#     Provides an S3 interface for registering images with the Image Service.
#     Mainly used for installations that must support euca2ools.
#
#   - euca2ools client.
#
#     A set of command-line interpreter commands for managing cloud resources.
#
# + Command-line clients and other interfaces
#
#   - nova client.
#
#     Enables users to submit commands as a tenant administrator or end user.
#
#   - nova-manage client.
#
#     Enables cloud administrators to submit commands.
#
# + Other components
#
#   - The queue.
#
#     A central hub for passing messages between daemons.
#
#   - SQL database.
#
#     Stores most build-time and runtime states for a cloud infrastructure.
#     Includes instance types that are available for use, instances in use,
#     available networks, and projects.
#
# nova api port: 8774
# nova-novncproxy port: 6080

compute/compute.sh
compute/compute_node.sh

# Networking service
# ------------------
# + OpenStack Networking (neutron)
# + Legacy networking (nova-network)
#
# neutron api port: 9696
network/neutron.sh
network/neutron_node.sh
network/nova_configure.sh

# vim: ts=4 sw=4 et tw=79
