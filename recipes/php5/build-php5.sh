#!/bin/bash

# Super helpful guide to building php5 on Debian
# https://gist.github.com/Bo98/c774c3298c0a8f4ca1b8

old_pwd=`pwd`

apt-get source php5 php5-json
sudo apt-get install libjson-c-dev

cd php5-*
DEB_BUILD_OPTIONS=nocheck debuild -us -uc -b -j6
cd $old_pwd

sudo dpkg -i php5-dev*

# pho-json

cd php-json*
DEB_BUILD_OPTIONS=nocheck debuild -us -uc -b -j6
cd $old_pwd

# pthreads

cd pthreads
git clone https://github.com/krakjoe/pthreads.git pthreads-git

cd pthreads-git
git checkout PHP5
phpize
./configure
make -j6
