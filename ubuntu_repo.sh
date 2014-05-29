#!/bin/sh

apt-get install python python-setuptools python-pip -y

apt-get install software-properties-common -y
apt-get install python-software-properties -y

add-apt-repository cloud-archive:icehouse -y
apt-get update
apt-get dist-upgrade

# vim: ts=4 sw=4 et tw=79
