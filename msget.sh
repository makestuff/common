#!/bin/sh
if [ $# != 1 ]; then
	echo "$0 <repo>"
	exit 1
fi
if [ -e ${1} ]; then
	echo "$1 already exists"
	exit 1
fi
wget --no-check-certificate -O ${1}.tgz https://github.com/makestuff/${1}/tarball/master
tar zxf ${1}.tgz
mv makestuff-${1}-* ${1}
rm -f zxf ${1}.tgz
