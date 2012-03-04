#
# Copyright (C) 2009-2012 Chris McClelland
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
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
