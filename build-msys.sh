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
mkdir -p all
cd all/
wget 'http://prdownloads.sourceforge.net/mingw/make-3.81-3-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/tar-1.23-1-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/gzip-1.3.12-2-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/grep-2.5.4-2-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/findutils-4.4.2-2-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/diffutils-2.8.7.20071206cvs-3-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/coreutils-5.97-3-msys-1.0.13-ext.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/coreutils-5.97-3-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/msysCORE-1.0.17-1-msys-1.0.17-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/termcap-0.20050421_1-2-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/bzip2-1.0.5-2-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/bash-3.1.17-4-msys-1.0.16-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/wget-1.12-1-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/patch-2.6.1-1-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/unzip-6.0-1-msys-1.0.13-bin.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/libiconv-1.13.1-2-msys-1.0.13-dll-2.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/libintl-0.17-2-msys-dll-8.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/libregex-1.20090805-2-msys-1.0.13-dll-1.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/libtermcap-0.20050421_1-2-msys-1.0.13-dll-0.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/libopenssl-1.0.0-1-msys-1.0.13-dll-100.tar.lzma?download'
wget 'http://prdownloads.sourceforge.net/mingw/sed-4.2.1-2-msys-1.0.13-bin.tar.lzma?download'
wget -O 7za920.zip 'http://prdownloads.sourceforge.net/sevenzip/7-Zip/9.20/7za920.zip?download'
rm -rf unpack ../msys
mkdir -p unpack
cd unpack/
unzip ../7za920.zip
for i in ../*.tar.lzma*; do tar --lzma -xf $i; done
cd ..
mkdir -p ../msys
mkdir -p ../msys/bin
mkdir -p ../msys/etc
mkdir -p ../msys/var/tmp
cat > ../msys/etc/profile <<EOF
# For Visual Studio Express 2010:
export MSVC=10.0
export MSWSDK=v7.0A
#export MSWSDK=v7.1
# For Visual Studio Express 2008:
#export MSVC=9.0
#export MSWSDK=v6.0A

export PATH="/bin:.:\$PATH"
if [ ! -e "/c/Program Files/Microsoft SDKs/Windows/\$MSWSDK" ]; then
  if [ ! -e "/c/Program Files/Microsoft SDKs/Windows" ]; then
    echo "You don't seem to have any Microsoft SDKs installed!"
  else
    echo "Cannot find Windows SDK version \$MSWSDK."
    echo "Are you sure MSWSDK is set correctly in /etc/profile?"
    echo "These are the Windows SDKs you appear to have installed:"
    ls "/c/Program Files/Microsoft SDKs/Windows"
  fi
fi
if [ \${PROCESSOR_ARCHITEW6432:-null} = null ]; then
  # We're not in WOW64 so this is probably an x86 system
  if [ ! -e "/c/Program Files/Microsoft Visual Studio \$MSVC" ]; then
    echo "Cannot find Visual Studio version \$MSVC."
    echo "Have you set MSVC correctly in /etc/profile?"
	 echo "These are the Visual Studio versions you appear to have installed:"
    ls "/c/Program Files" | grep "Microsoft Visual Studio"
  fi
  export INCLUDE="C:/Program Files/Microsoft Visual Studio \$MSVC/VC/INCLUDE;C:/Program Files/Microsoft SDKs/Windows/\$MSWSDK/include"
  export LIB="C:/Program Files/Microsoft Visual Studio \$MSVC/VC/LIB;C:/Program Files/Microsoft SDKs/Windows/\$MSWSDK/lib"
  export PATH="/c/Program Files/Microsoft Visual Studio \$MSVC/VC/bin:\$PATH"
  export PATH="/c/Program Files/Microsoft SDKs/Windows/\$MSWSDK/bin:\$PATH"
  export PATH="/c/Program Files/Microsoft Visual Studio \$MSVC/Common7/IDE:\$PATH"
else
  # We're in WOW64 so this is probably an x86_64 system
  if [ ! -e "/c/Program Files (x86)/Microsoft Visual Studio \$MSVC" ]; then
    echo "Cannot find Visual Studio version \$MSVC."
    echo "Have you set MSVC correctly in /etc/profile?"
	 echo "These are the Visual Studio versions you appear to have installed:"
    ls "/c/Program Files (x86)" | grep "Microsoft Visual Studio"
  fi
  export INCLUDE="C:/Program Files (x86)/Microsoft Visual Studio \$MSVC/VC/INCLUDE;C:/Program Files/Microsoft SDKs/Windows/\$MSWSDK/include"
  export LIB="C:/Program Files (x86)/Microsoft Visual Studio \$MSVC/VC/LIB;C:/Program Files/Microsoft SDKs/Windows/\$MSWSDK/lib"
  export PATH="/c/Program Files (x86)/Microsoft Visual Studio \$MSVC/VC/bin:\$PATH"
  export PATH="/c/Program Files/Microsoft SDKs/Windows/\$MSWSDK/bin:\$PATH"
  export PATH="/c/Program Files (x86)/Microsoft Visual Studio \$MSVC/Common7/IDE:\$PATH"
fi
export PS1="\${USERNAME}@\${HOSTNAME}\$ "
EOF
cat > ../msys/README <<EOF
This directory contains a minimal build system comprising MinGW binaries downloaded from SourceForge,
where you can get copies of the software licenses and source code for these binaries. I have packaged
it like this purely for your convenience; you can construct your own copy of this by running the
makestuff.sh script on a GNU-like machine:

  https://github.com/makestuff/common/raw/master/makestuff.sh

To use, you should unpack the "makestuff" directory to C:/ and make a desktop shortcut to
C:\makestuff\msys\bin\sh.exe --login. The resulting command prompt assumes you have Microsoft Visual
Studio Express 2010 installed. If you want to use VS2008, edit etc/profile.

To install vim:

mkdir vim
cd vim
wget -q 'http://prdownloads.sourceforge.net/mingw/vim-7.3-2-msys-1.0.16-bin.tar.lzma?download'
7za.exe x -so vim-7.3-2-msys-1.0.16-bin.tar.lzma | tar xf -
mv bin/vim.exe /bin/
cd ..
rm -rf vim
EOF
cp unpack/7za.exe ../msys/bin/
cp unpack/bin/bunzip2.exe ../msys/bin/
cp unpack/bin/bzip2.exe ../msys/bin/
cp unpack/bin/cat.exe ../msys/bin/
cp unpack/bin/cmp.exe ../msys/bin/
cp unpack/bin/cp.exe ../msys/bin/
cp unpack/bin/dd.exe ../msys/bin/
cp unpack/bin/diff.exe ../msys/bin/
cp unpack/bin/dirname.exe ../msys/bin/
cp unpack/bin/echo.exe ../msys/bin/
cp unpack/bin/env.exe ../msys/bin/
cp unpack/bin/find.exe ../msys/bin/
cp unpack/bin/grep.exe ../msys/bin/
cp unpack/bin/gunzip ../msys/bin/
cp unpack/bin/gzip.exe ../msys/bin/
cp unpack/bin/ls.exe ../msys/bin/
cp unpack/bin/make.exe ../msys/bin/
cp unpack/bin/mkdir.exe ../msys/bin/
cp unpack/bin/msys-1.0.dll ../msys/bin/
cp unpack/bin/msys-crypto-1.0.0.dll ../msys/bin/
cp unpack/bin/msys-iconv-2.dll ../msys/bin/
cp unpack/bin/msys-intl-8.dll ../msys/bin/
cp unpack/bin/msys-regex-1.dll ../msys/bin/
cp unpack/bin/msys-ssl-1.0.0.dll ../msys/bin/
cp unpack/bin/msys-termcap-0.dll ../msys/bin/
cp unpack/bin/mv.exe ../msys/bin/
cp unpack/bin/patch.exe ../msys/bin/paatch.exe
cp unpack/bin/pwd.exe ../msys/bin/
cp unpack/bin/rm.exe ../msys/bin/
cp unpack/bin/sed.exe ../msys/bin/
cp unpack/bin/sh.exe ../msys/bin/
cp unpack/bin/tail.exe ../msys/bin/
cp unpack/bin/tar.exe ../msys/bin/
cp unpack/bin/tr.exe ../msys/bin/
cp unpack/bin/uname.exe ../msys/bin/
cp unpack/bin/unzip.exe ../msys/bin/
cp unpack/bin/wget.exe ../msys/bin/
cp unpack/etc/inputrc.default ../msys/etc/
cp unpack/etc/termcap ../msys/etc/
cp unpack/etc/wgetrc ../msys/etc/
cd ..
rm -rf all
#cp -rp build-msys.sh msys/
#zip -r msys.zip msys
#rm -rf msys
