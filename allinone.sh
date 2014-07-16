#!/bin/sh

# ===========================
# Install OpenStack on Ubuntu
# ===========================

export OS_USERNAME=
export OS_PASSWORD=
export OS_TENANT_NAME=
export OS_AUTH_URL=

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

database/db.sh

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

./ubuntu_repo.sh

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

identity/keystone.sh
identity/configure.sh

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

image/glance.sh

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
#  The metadata service is implemented by either the nova-api service or the
#  nova-api-metadata service. Accepts metadata requests from instances. The
#  nova-api-metadata service is generally only used when you run in
#  **multi-host** mode with nova-network installations.

#  Hosts access the metadata service at 169.254.169.254:80, and this is
#  translated to metadata_host:metadata_port by an iptables rule established by
#  the nova-network service. In multi-host mode, you can set metadata_host to
#  127.0.0.1.
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
# nova metadata api port: 8775
# nova-novncproxy port: 6080

compute/compute.sh
compute/compute_node.sh

# Networking service
# ------------------
# + OpenStack Networking (neutron)
# + Legacy networking (nova-network)
#
# Every virtual instance is automatically assigned a private IP address. You
# may optionally assign public IP addresses to instances. OpenStack uses the
# term "floating IP" to refer to an IP address (typically public) that can be
# dynamically added to a running virtual instance. OpenStack Compute uses
# Network Address Translation (NAT) to assign floating IPs to virtual
# instances.
#
# public_interface in nova.conf file to specify which interface the nova-network
# service will bind public IP addresses.
#
# neutron api port: 9696

network/neutron.sh
network/neutron_network_node.sh
network/neutron_compute_node.sh
network/local/local_settings.sh
network/local/create_ext-net.sh
network/local/create_int-net.sh

# network/nova-network.sh

# Dashboard service
# -----------------
# The OpenStack dashboard, also known as Horizon, is a Web interface that
# enables cloud administrators and users to manage various OpenStack resources
# and services.
#
# curl http://keystone/horizon
dashboard/dashboard.sh

# Block Storage service
# ---------------------
# The Block Storage service enables management of volumes, volume snapshots,
# and volume types. It includes the following components:
#
# + cinder-api
#
#   Accepts API requests and routes them to cinder-volume for action.
#
# + cinder-volume
#
#   Responds to requests to read from and write to the Block Storage database
#   to maintain state, interacting with other processes (like cinder-scheduler)
#   through a message queue and directly upon block storage providing hardware
#   or software. It can interact with a variety of storage providers through a
#   driver architecture.
#
# + cinder-scheduler daemon
#
#   Like the nova-scheduler, picks the optimal block storage provider node on
#   which to create the volume.
#
# + Messaging queue
#
#   Routes information between the Block Storage service processes.
#
# The Block Storage service interacts with Compute to provide volumes for
# instances.
#
# cinder api port: 8776
block_storage/cinder.sh
block_storage/cinder_node_prerun.sh
block_storage/cinder_node.sh

# Object Storage service
# ----------------------
# The Object Storage service is a highly scalable and durable multi-tenant
# object storage system for large amounts of unstructured data at low cost
# through a RESTful HTTP API.
#
# It includes the following components:
#
# + Proxy servers (swift-proxy-server).
#
#   Accepts Object Storage API and raw HTTP requests to upload files, modify
#   metadata, and create containers. It also serves file or container listings
#   to web browsers. To improve performance, the proxy server can use an
#   optional cache usually deployed with memcache.
#
# + Account servers (swift-account-server).
#
#   Manage accounts defined with the Object Storage service.
#
# + Container servers (swift-container-server).
#
#   Manage a mapping of containers, or folders, within the Object Storage
#   service.
#
# + Object servers (swift-object-server).
#
#   Manage actual objects, such as files, on the storage nodes.
#
# + A number of periodic processes.
#
#   Performs housekeeping tasks on the large data store. The replication
#   services ensure consistency and availability through the cluster. Other
#   periodic processes include auditors, updaters, and reapers.
#
# Configurable WSGI middleware that handles authentication. Usually the
# Identity Service.
#
# swift proxy port: 8080
# object_storage/swift_storage_node_prepare.sh
# object_storage/swift.sh
# object_storage/swift_add_storage_node.sh
# object_storage/swift_start.sh
# object_storage/swift_storage_node_start.sh

# Orchestration service
# ---------------------
# The Orchestration service consists of the following components:
#
# + heat command-line client.
#
#   A CLI that communicates with the heat-api to run AWS CloudFormation APIs.
#   End developers could also use the Orchestration REST API directly.
#
# + heat-api component.
#
#   Provides an OpenStack-native REST API that processes API requests by
#   sending them to the heat-engine over RPC.
#
# + heat-api-cfn component.
#
#   Provides an AWS Query API that is compatible with AWS CloudFormation and
#   processes API requests by sending them to the heat-engine over RPC.
#
# + heat-engine.
#
#   Orchestrates the launching of templates and provides events back to the API
#   consumer.
# orchestration/heat.sh

# Telemetry service
# -----------------
# The system consists of the following basic components:
#
# + A compute agent (ceilometer-agent-compute).
#
#   Runs on each compute node and polls for resource utilization statistics.
#   There may be other types of agents in the future, but for now we will focus
#   on creating the compute agent.
#
# + A central agent (ceilometer-agent-central).
#
#   Runs on a central management server to poll for resource utilization
#   statistics for resources not tied to instances or compute nodes.
#
# + A collector (ceilometer-collector).
#
#   Runs on one or more central management servers to monitor the message
#   queues (for notifications and for metering data coming from the agent).
#   Notification messages are processed and turned into metering messages and
#   sent back out onto the message bus using the appropriate topic. Telemetry
#   messages are written to the data store without modification.
#
# + An alarm notifier (ceilometer-alarm-notifier).
#
#   Runs on one or more central management servers to allow setting alarms
#   based on threshold evaluation for a collection of samples.
#
# + A data store.
#
#   A database capable of handling concurrent writes (from one or more
#   collector instances) and reads (from the API server).
#
# + An API server (ceilometer-api).
#
#   Runs on one or more central management servers to provide access to the
#   data from the data store.
#
# These services communicate by using the standard OpenStack messaging bus.
# Only the collector and API server have access to the data store.
# telemetry/ceilometer.sh
# telemetry/ceilometer_image_node.sh
# telemetry/ceilometer_compute_node.sh
# some bug
# telemetry/ceilometer_block_node.sh
# telemetry/ceilometer_object_node.sh

# Database service
# ----------------
# The Database service includes the following components:
#
# + python-troveclient command-line client.
#
# A CLI that communicates with the trove-api component.
#
# + trove-api component.
#
#   Provides an OpenStack-native RESTful API that supports JSON to provision
#   and manage Trove instances.
#
# + trove-conductor service.
#
#   Runs on the host, and receives messages from guest instances that want to
#   update information on the host.
#
# + trove-taskmanager service.
#
#   Instruments the complex system flows that support provisioning instances,
#   managing the lifecycle of instances, and performing operations on
#   instances.
#
# + trove-guestagent service.
#
#   Runs within the guest instance.  Manages and performs operations on the
#   database itself.
# echo "There are many bug in Icehouse. Wait next version!"

#
# vim: ts=4 sw=4 et tw=79
