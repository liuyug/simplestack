SimpleStack
===========
Try to make a simple openstack script to deploy on Ubuntu server.

Cloud Image
-----------

Cirros cloud image
~~~~~~~~~~~~~~~~~~
Download link: http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img

username: cirros

password: cubswin:)

Ubuntu cloud image
~~~~~~~~~~~~~~~~~~
Ubuntu 12.04: http://cloud-images.ubuntu.com/precise/20140526/precise-server-cloudimg-amd64-disk1.img

Ubuntu 14.04: http://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img

username: ubuntu

password: no, use rsa key

Install
-------

.. note::

   add fixed ip address into ``/etc/hosts``, such as::

       192.168.203.10 node1

    ``hostname -s`` will be "node1"

All in one
~~~~~~~~~~~

All install on single machine::

    allinone.sh 2>&1 | tee out.log

all username and password are stored in file, "stack.conf".

make user "rc" file::

    mkrc.sh <KEYSTONE SERVER> <USER> <PASSWORD> <TENANT>

Step by step
~~~~~~~~~~~~
ubuntu_rep.sh
ntp/ntp.sh

How to use
-----------
::

    . admin-openrc.sh
    keystone user-list
    glance image-list
    nova image-list

.. note::

   You will lose the volume of block stoarge and the disk of object storage after machine reboot. Run remount_vg.sh and remount_disk.sh to refind them.

Bug
----
"trove" could not been installed for ubuntu package bug.

