#!/bin/bash

yum -y groupinstall "Development Tools"

mkdir -p ~/tmp/{usr,etc,var,libs,install,downloads,tar}

# cd ~/tmp/downloads
# curl -L -O http://downloads.sourceforge.net/freetype/freetype-2.6.1.tar.bz2
# curl -L -O http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.11.1.tar.bz2
# curl -L -O http://xmlsoft.org/sources/libxml2-2.9.2.tar.gz
# curl -L -O http://poppler.freedesktop.org/poppler-0.37.0.tar.xz
# cd -
# ls ~/tmp/downloads/*.tar.* | xargs -i tar xf {} -C ~/tmp/libs/

pushd .

####################################
cd ~/tmp/libs/freetype*
sed -e "/AUX.*.gxvalid/s@^# @@" \
    -e "/AUX.*.otvalid/s@^# @@" \
    -i modules.cfg              &&

sed -e 's:.*\(#.*SUBPIXEL.*\) .*:\1:' \
    -i include/freetype/config/ftoption.h  &&

./configure --prefix=/root/tmp/usr --disable-static &&
make
make install 

####################################
cd ~/tmp/libs/libxml*
PKG_CONFIG_PATH=~/tmp/usr/lib/pkgconfig/:$PKG_CONFIG_PATH \
./configure --prefix=/root/tmp/usr --disable-static --with-history &&
make
make install

####################################
cd ~/tmp/libs/fontconfig*
export FONTCONFIG_PKG=`pwd`

PKG_CONFIG_PATH=~/tmp/usr/lib/pkgconfig/:$PKG_CONFIG_PATH \
./configure --prefix=/root/tmp/usr        \
            --sysconfdir=/root/tmp/etc    \
            --localstatedir=/var \
            --disable-docs       \
            --enable-libxml2 &&
make
make install

####################################
cd ~/tmp/libs/poppler*
PKG_CONFIG_PATH=~/tmp/usr/lib/pkgconfig/:$FONTCONFIG_PKG:$PKG_CONFIG_PATH \
./configure --prefix=/var/task      \
            --sysconfdir=/var/task/etc           \
            --enable-build-type=release \
            --enable-cmyk               \
            --enable-xpdf-headers && make

make install DESTDIR="/root/tmp/install"

unset FONTCONFIG_PKG
popd

tar -C ~/tmp/install/var/task \
    --exclude='include' \
    --exclude='share'   \
    -zcvf ~/tmp/tar/poppler.tar.gz .

#aws s3 cp ~/tmp/tar/poppler.tar.gz s3://"${S3BUCKET}"/poppler.tar.gz