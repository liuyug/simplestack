#!/bin/sh

set -o xtrace

add-apt-repository cloud-archive:icehouse -y
apt-get update
apt-get dist-upgrade -y

apt-get install python python-setuptools python-pip -y
apt-get install software-properties-common -y
apt-get install python-software-properties -y

# my customized application
apt-get install vim curl lynx tcpdump htop -y


# vim: ts=4 sw=4 et tw=79
