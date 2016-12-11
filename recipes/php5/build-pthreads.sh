#!/bin/bash

# There are no official releases from the 'PHP5' branch,
# but because the debian spec requires a numeric version
# number, we use the latest release/tag

version=3.1.5

old_pwd=`pwd`
INSTALL=~/packages/php5/pthreads/modules
buildtemp=~/packages/php5/pthreads/temp

echo "Installing fpm.."
#sudo gem install fpm

# git stuff
git clone https://github.com/krakjoe/pthreads.git pthreads

cd pthreads
git checkout PHP5
gitref=`git rev-parse --short HEAD`

# build
phpize
./configure
make -j6

# build package tree
install -m 0644 -D $INSTALL/pthreads.so $buildtemp/`php-config --extension-dir`/pthreads.so
install -m 0644 -D $old_pwd/pthreads.ini $buildtemp/etc/php5/mods-available/pthreads.ini

cd ~/packages/php5

# Package building
fpm -f -s dir -t deb -n php5-pthreads -v $version --iteration git-$gitref -C $buildtemp \
--description "pthreads module for php5-zts, git version $gitref" \
-d php5-common \
-d libc6 \
etc usr
