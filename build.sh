#!/bin/bash -ex
# Copyright (c) 2014-2015 Arduino LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# linux -   ./build.all.new.bash
# windows - ./build.all.new.bash -h=i686-w64-mingw32"

# Original source:
# https://github.com/arduino/Arduino/issues/660#issuecomment-120433193

# Changelog:
# Removed gcc patch (no longer required with gcc 5.3)
# Updated avr-libc download page
# Added -j --jobs option
# Added avrdude

# TODO
# Remove build paramater? http://airs.com/ian/configure/configure_6.html
# https://github.com/NicoHood/PinChangeInterrupt/commit/f81d538ce287561764811c9db3dee2fca9da0c66

# Download mirrors to lookup the latest version:
# ftp://ftp.gnu.org/gnu/binutils/
# ftp://gcc.gnu.org/pub/gcc/releases/
# http://isl.gforge.inria.fr/
# http://www.bastoul.net/cloog/pages/download/
# http://mirror.switch.ch/ftp/mirror/gnu/gmp/
# http://mirror.switch.ch/ftp/mirror/gnu/mpfr/
# ftp://ftp.gnu.org/gnu/mpc/
# http://download.savannah.gnu.org/releases/avr-libc/
# http://download.savannah.gnu.org/releases/avrdude/

export BINUTILS_VERSION=2.26
export GCC_VERSION=6.1.0
export ISL_VERSION=0.16.1
export CLOOG_VERSION=0.18.4
export GMP_VERSION=6.1.0
export MPFR_VERSION=3.1.4
export MPC_VERSION=1.0.3
export AVRLIBC_VERSION=2.0.0
export AVRDUDE_VERSION=6.3

for i in "$@"
do
case $i in
        -h=*|--host=*)
        export HOST="${i#*=}"
        ;;
        -p=*|--path=*)
        export PATH=$PATH:"${i#*=}"
        ;;
        -cc=*)
        export CC="${i#*=}"
        ;;
        -cxx=*)
        export CXX="${i#*=}"
        ;;
        -cflags=*)
        export CFLAGS="${i#*=}"
        ;;
        -cxxflags=*)
        export CXXFLAGS="${i#*=}"
        ;;
        -ldflags=*)
        export LDFLAGS="${i#*=}"
        ;;
        -j=*|--jobs=*)
        export JOBS="${i#*=}"
        ;;
        clean)
        rm -rf gcc-$GCC_VERSION
        rm -rf binutils-$BINUTILS_VERSION
        rm -rf avr-libc-$AVRLIBC_VERSION
        rm -rf avrdude-$AVRDUDE_VERSION
        rm -rf gcc-build
        exit
        ;;
        cleanall)
        rm -rf gcc-$GCC_VERSION
        rm -rf binutils-$BINUTILS_VERSION
        rm -rf avr-libc-$AVRLIBC_VERSION
        rm -rf avrdude-$AVRDUDE_VERSION
        rm -rf gcc-build
        rm *.tar.bz2
        rm *.tar.gz
        exit
        ;;
        *)
        # unknown option
        ;;
esac
done

export home=`pwd`

if [ "$JOBS" == "" ]; then
export JOBS=$(nproc)
fi

# On linux Elementary OS laptop:
# /binutils-2.26/config.guess x86_64-pc-linux-gnu
# /gcc-5.3.0/config.guess x86_64-unknown-linux-gnu
# /avr-libc-2.0.0/config.guess x86_64-unknown-linux-gnu
# config_guess=`./binutils-$BINUTILS_VERSION/config.guess`

export pkgdir=${home}/bin
rm -rf $pkgdir
mkdir -p $pkgdir

################################################################################
# binutils
################################################################################

# Download
if [ ! -f binutils-$BINUTILS_VERSION.tar.bz2 ]; then
wget ftp://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.bz2
fi

# Extract and enter directory
rm -rf binutils-$BINUTILS_VERSION
tar xf binutils-$BINUTILS_VERSION.tar.bz2
cd binutils-$BINUTILS_VERSION

# Patch and configure
curl https://projects.archlinux.org/svntogit/community.git/plain/trunk/avr-size.patch?h=packages/avr-binutils > 01-avr-size.patch
patch -Np0 < 01-avr-size.patch

sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -O2/" libiberty/configure
if [ "$HOST" == "" ]; then
export HOST=`./config.guess`
fi

./configure \
        --prefix=$pkgdir \
        --with-bugurl=https://github.com/arduino/toolchain-avr/ \
        --enable-gold \
        --enable-ld=default \
        --enable-plugins \
        --enable-threads \
        --with-pic \
        --enable-lto \
        --disable-shared \
        --disable-werror \
        --disable-multilib \
        --host=$HOST \
        --build=$HOST \
        --target=avr

make configure-host

# Compile and Install
make -j$JOBS
make install

export HOST=""

################################################################################
# gcc
################################################################################

cd $home

# Download gcc and dependencies
if [ ! -f gcc-$GCC_VERSION.tar.bz2 ]; then
wget ftp://gcc.gnu.org/pub/gcc/releases/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.bz2
fi
if [ ! -f isl-$ISL_VERSION.tar.bz2 ]; then
wget http://isl.gforge.inria.fr/isl-$ISL_VERSION.tar.bz2
fi
if [ ! -f cloog-$CLOOG_VERSION.tar.gz ]; then
wget http://www.bastoul.net/cloog/pages/download/cloog-$CLOOG_VERSION.tar.gz
fi
if [ ! -f gmp-$GMP_VERSION.tar.bz2 ]; then
wget http://mirror.switch.ch/ftp/mirror/gnu/gmp/gmp-$GMP_VERSION.tar.bz2
fi
if [ ! -f mpfr-$MPFR_VERSION.tar.bz2 ]; then
wget http://mirror.switch.ch/ftp/mirror/gnu/mpfr/mpfr-$MPFR_VERSION.tar.bz2
fi
if [ ! -f mpc-$MPC_VERSION.tar.gz ]; then
wget http://www.multiprecision.org/mpc/download/mpc-$MPC_VERSION.tar.gz
fi

# Start with a fresh build
rm -rf gcc-$GCC_VERSION

# Extract
tar xf gcc-$GCC_VERSION.tar.bz2
tar xf isl-$ISL_VERSION.tar.bz2
tar xf cloog-$CLOOG_VERSION.tar.gz
tar xf gmp-$GMP_VERSION.tar.bz2
tar xf mpfr-$MPFR_VERSION.tar.bz2
tar xf mpc-$MPC_VERSION.tar.gz

# Remove builtin dependencies of gcc and and use our custom versions.
rm -rf gcc-$GCC_VERSION/cloog gcc-$GCC_VERSION/isl gcc-$GCC_VERSION/gmp gcc-$GCC_VERSION/mpfr gcc-$GCC_VERSION/mpc

# Copy our custom versions
mv cloog-$CLOOG_VERSION gcc-$GCC_VERSION/cloog
mv isl-$ISL_VERSION gcc-$GCC_VERSION/isl
mv gmp-$GMP_VERSION gcc-$GCC_VERSION/gmp
mv mpfr-$MPFR_VERSION gcc-$GCC_VERSION/mpfr
mv mpc-$MPC_VERSION gcc-$GCC_VERSION/mpc

cd gcc-$GCC_VERSION/

sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -O2/" {libiberty,gcc}/configure
if [ "$HOST" == "" ]; then
export HOST=`./config.guess`
fi

echo $GCC_VERSION > gcc/BASE-VER

export CFLAGS_FOR_TARGET='-O2 -pipe'
export CXXFLAGS_FOR_TARGET='-O2 -pipe'

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgdir}/$HOST/avr/lib/
export PATH=$PATH:${pkgdir}/bin/

cd $home

rm -rf gcc-build
mkdir gcc-build && cd gcc-build

# Configure
$home/gcc-$GCC_VERSION/configure \
                --disable-install-libiberty \
                --disable-libssp \
                --disable-libstdcxx-pch \
                --disable-libunwind-exceptions \
                --disable-nls \
                --enable-fixed-point \
                --enable-long-long \
                --disable-werror \
                --disable-__cxa_atexit \
                --enable-checking=release \
                --enable-clocale=gnu \
                --enable-cloog-backend=isl \
                --enable-gnu-unique-object \
                --with-avrlibc=yes \
                --with-dwarf2 \
                --enable-languages=c,c++ \
                --disable-libada \
                --disable-doc \
                --enable-lto \
                --enable-gold \
                --disable-plugin \
                --prefix=$pkgdir \
                --disable-shared \
                --with-gnu-ld \
                --host=$HOST \
                --build=$HOST \
                --target=avr

#remove __HAVE_MALLOC_H__ if cross compiling for OSX
#http://glaros.dtc.umn.edu/gkhome/node/694

# Compile and install
make -j$JOBS
make -j1 install-strip

find $pkgdir/lib -type f -name "*.a" -exec ${pkgdir}/bin/avr-strip --strip-debug '{}' \;

rm -rf $pkgdir/share/man/man7
rm -rf $pkgdir/share/info

################################################################################
# avr-libc
################################################################################

cd $home

# Download
if [ ! -f avr-libc-$AVRLIBC_VERSION.tar.bz2 ]; then
wget http://download.savannah.gnu.org/releases/avr-libc/avr-libc-$AVRLIBC_VERSION.tar.bz2
fi

# Extract and enter directory
rm -rf avr-libc-$AVRLIBC_VERSION
tar xf avr-libc-$AVRLIBC_VERSION.tar.bz2
cd avr-libc-$AVRLIBC_VERSION/

# Configure
./bootstrap --prefix=$pkgdir/
CC=${pkgdir}/bin/avr-gcc ./configure --prefix=$pkgdir/ --build=$HOST --host=avr

# Compile and install
make -j$JOBS
make install

################################################################################
# avrdude
################################################################################

cd $home

# Download
if [ ! -f avrdude-$AVRDUDE_VERSION.tar.gz ]; then
wget http://download.savannah.gnu.org/releases/avrdude/avrdude-$AVRDUDE_VERSION.tar.gz
fi

# Extract and enter directory
rm -rf avrdude-$AVRDUDE_VERSION
tar xf avrdude-$AVRDUDE_VERSION.tar.gz
cd avrdude-$AVRDUDE_VERSION

# Configure
mkdir obj-avr
cd obj-avr
../configure --prefix=$pkgdir/

# Compile and install
make -j$JOBS
make install
