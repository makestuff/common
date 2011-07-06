#!/bin/bash
export DATE=$(date +%Y%m%d)
mkdir makestuff
cd makestuff
wget -O common.tar.gz --no-check-certificate https://github.com/makestuff/common/tarball/master
tar zxf common.tar.gz 
mv makestuff-common-* common
rm -f common.tar.gz 
cd common/
./build-msys.sh 
mv msys ..
cd ..
mkdir libs
mkdir apps
mkdir 3rd
cd ..
zip -r makestuff-win32-${DATE}.zip makestuff
mv makestuff-win32-${DATE}.zip /mnt/ukfsn/bin/
rm -rf makestuff/msys
tar zcf makestuff-lindar-${DATE}.tar.gz makestuff
mv makestuff-lindar-${DATE}.tar.gz /mnt/ukfsn/bin/
rm -rf makestuff
