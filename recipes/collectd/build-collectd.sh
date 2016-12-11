#!/bin/bash

sudo apt-get install dpkg-dev pkg-config git
sudo apt-get build-dep collectd-core
sudo apt-get install libvarnishapi

git clone https://github.com/ti-mo/collectd.git git-collectd

apt-get source collectd-core

old_pwd=`pwd`

cd collectd-*
make distclean
cp $old_pwd/git-collectd/src/netlink.c src/netlink.c
cp $old_pwd/git-collectd/src/types.db src/types.db
./configure
DEB_BUILD_OPTIONS=nocheck debuild -us -uc
