#!/usr/bin/bash

export ZLIB=zlib-1.2.11
export PCRE=pcre-8.44
export OPENSSL=openssl-1.1.1i
export LIGHTTPD=lighttpd-1.4.58

echo $BLD

#############################################################
# download
#############################################################

mkdir -p src
cd src
wget -nc https://toolchains.bootlin.com/downloads/releases/sources/$ZLIB/$ZLIB.tar.xz
wget -nc https://ftp.exim.org/pub/pcre/$PCRE.tar.gz
wget -nc https://www.openssl.org/source/$OPENSSL.tar.gz
wget -nc https://download.lighttpd.net/lighttpd/releases-1.4.x/$LIGHTTPD.tar.xz

if [ ! -d ./$ZLIB ]; then
tar xvf $ZLIB.tar.xz
fi

if [ ! -d ./$PCRE ]; then
tar xvf $PCRE.tar.gz
fi

if [ ! -d ./$OPENSSL ]; then
tar xvf $OPENSSL.tar.gz
fi

if [ ! -d ./$LIGHTTPD ]; then
tar xvf $LIGHTTPD.tar.xz
fi
cd ..

##############################################################
export NDK="/opt/sdk/android-sdk-linux/ndk/21.4.7075529"
export ANDROID_NDK_HOME=/opt/sdk/android-sdk-linux/ndk/21.4.7075529
export BLD=/opt/sdk/lighthttpd
export INSTALL_PREFIX=$BLD/src/extras
export PKG_CONFIG_PATH=$INSTALL_PREFIX/lib/pkgconfig
export INSTALL_PREFIX=$BLD/src/extras

export TARGET=aarch64-linux-android
export ARM=aarch64-linux-android
export API=21
export ANDROID_NDK_HOME=$NDK
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64

export AR=$TOOLCHAIN/bin/$ARM-ar
export AS=$TOOLCHAIN/bin/$ARM-as
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
export LD=$TOOLCHAIN/bin/$ARM-ld
export RANLIB=$TOOLCHAIN/bin/$ARM-ranlib
export STRIP=$TOOLCHAIN/bin/$ARM-strip
export CFLAGS="-fPIE"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-fPIE -pie -L${INSTALL_PREFIX}/lib"
export SYSROOT=$NDK/sysroot

export CPPFLAGS="-I${INSTALL_PREFIX}/include -I${SYS_ROOT}/include"

if [ ! -d $NDK ]; then
echo "Please configure NDK"
exit
fi

$CC $CFLAGS $CPPFLAGS -c $INSTALL_PREFIX/lib/glob.c
$AR r $BLD/libglob.a $BLD/glob.o

export LIBS=$BLD/glob.o

set -e

if [ ! -f "$BLD/include/zlib.h" ]; then
cd $BLD/src/$ZLIB
./configure --prefix=$BLD --static
make install
fi

if [ ! -f "$BLD/include/pcre.h" ]; then
cd $BLD/src/$PCRE
./configure --host=$TARGET --prefix=$BLD --disable-shared
make install
fi

if [ ! -f "$BLD/include/openssl/ssl.h" ] || [[ ! -f "$BLD/lib/libcrypto.a" ]] || [[ ! -f "$BLD/lib/libssl.a" ]]; then
echo BUILDING OPENSSL
cd $BLD/src/$OPENSSL
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH
# ./Configure android-arm no-shared -D__ANDROID_API__=$API --prefix=$BLD
./Configure android-arm64 no-shared -D__ANDROID_API__=$API --prefix=$BLD
make install
fi

echo BUILDING LIGHTTPD
cd $BLD/src/$LIGHTTPD
if [ -f "Makefile" ]; then
make distclean
fi
rm -f src/plugin-static.h
cp $BLD/plugin-static.h ./src/
CPPFLAGS=-DLIGHTTPD_STATIC LIGHTTPD_STATIC=yes ./configure -C --host=$TARGET --enable-static=yes --enable-shared=no --disable-shared --prefix=$BLD --disable-ipv6 --with-pcre=$BLD --with-zlib=$BLD --with-openssl=$BLD
# export CPPFLAGS="${CPPFLAGS} -DLIGHTTPD_STATIC LIGHTTPD_STATIC=yes -I${INSTALL_PREFIX}/include"
# export LDFLAGS="${LDFLAGS} -L${INSTALL_PREFIX}/lib "
# ./configure -C --host=$TARGET --enable-static=yes --enable-shared=no --disable-shared --prefix=$BLD --disable-ipv6 --with-pcre=$BLD --with-zlib=$BLD --with-openssl=$BLD
sed -i.bak '/lighttpd-mod_webdav/d' ./src/Makefile
make install-strip



