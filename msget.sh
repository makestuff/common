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
if [ $# != 1 ]; then
	echo "$0 <repo>"
	exit 1
fi
if [ -e ${1} ]; then
	echo "$1 already exists"
	exit 1
fi
wget --no-check-certificate -O ${1}.tgz https://api.github.com/repos/makestuff/${1}/tarball
tar zxf ${1}.tgz
mv makestuff-${1}-* ${1}
rm -f zxf ${1}.tgz
