#!/bin/sh
if [ $# != 1 ]; then
	echo "$0 <repo>"
	exit 1
fi
if [ -e ${1} ]; then
	echo "$1 already exists"
	exit 1
fi
git clone git@github.com:makestuff/${1}.git ${1}
