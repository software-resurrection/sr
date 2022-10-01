## Compiling and testing sqlite-2.2.1 in a modern platform. This has been
## tested in the following platform.
##
## Operating System: Debian GNU/Linux 11 (bullseye)
## Hardware: Intel(R) Core(TM) i9-9980HK CPU @ 2.40GHz, 16 cores, x86_64, Little Endian
##
## Author : Abhishek Dutta <https://abhishekdutta.org>
## Date   : 19-Feb-2022
##
## Usage: ./apply-patch.sh OUTDIR
## e.g. ./apply-patch.sh /tmp/sqlite/

PATCHDIR=$(pwd)
OUTDIR=$1

if [ ! -f "${PATCHDIR}/apply-patch.sh" ]; then
    echo "This script should be executed from the folder containing apply-patch.sh file"
    exit
fi

if [ "$#" -lt 1 ]; then
    echo "Usage: ${0} OUTDIR"
    exit
fi

if [ ! -d "$OUTDIR" ]; then
    echo "${OUTDIR} does not exist!"
    exit
fi

##
## Download source for sqlite-2.2.1
##
if [ ! -f "${OUTDIR}/SQLite-61c38f3b.tar.gz" ]; then
    cd $OUTDIR
    wget https://www.sqlite.org/src/tarball/61c38f3b/SQLite-61c38f3b.tar.gz
    tar -zxvf SQLite-61c38f3b.tar.gz
    mv SQLite-61c38f3b sqlite
    cd sqlite
    git init .
    git add .
    git commit -m "Version 2.2.1 (CVS 452) (check-in: 61c38f3bfef430f3, https://www.sqlite.org/src/info/61c38f3bfef430f3)"
fi

##
## Apply patches to sqlite-2.2.1
##
GIT_REV_COUNT=`git -C ${OUTDIR}/sqlite/ rev-list --count HEAD`

if [[ $GIT_REV_COUNT -eq 1 ]]; then
    cd "${OUTDIR}/sqlite"
    ## Patch 1: apply vararg patch
    git apply $PATCHDIR/1-varargs.patch
    git commit -a -m "varargs compilation issue in tool/lemon.c fixed by borrowing code from sqlite-2.8.1 release (check-in: 590f963b6599e4e2)"

    ## Patch 2: apply getline patch
    git apply $PATCHDIR/2-getline.patch
    git commit -a -m "renamed getline() method to local_getline() to avoid name conflict with standard library (check-in: 558969ee8697180c)"

    ## Patch 3: extern patch
    git apply $PATCHDIR/3-extern.patch
    git commit -a -m "defined variable as extern in to resolve multiple definition error"

    ## Patch 4: pointer address is 64 bit not 32 bit
    #git apply $PATCHDIR/4-pointer-address-64bit-not-32bit.patch
    #git commit -a -m "used %p format specifier instead of %x to obtain 64 bit pointer address (researched by Abhishek Dutta)"
fi

##
## Build patched version of sqlite-2.2.1
##
if [ ! -d "${OUTDIR}/build" ]; then
    cd $OUTDIR
    mkdir build
    cd build
    ../sqlite/configure
    make  # fails with TCL issue
fi

##
## Build test of patched sqlite-2.2.1
##

## Download and compile tcl8.6.12
if [ ! -f "${OUTDIR}/dep/src/tcl8.6.12-src.tar.gz" ]; then
    mkdir -p $OUTDIR/dep/src
    cd $OUTDIR/dep/src
    wget https://prdownloads.sourceforge.net/tcl/tcl8.6.12-src.tar.gz
    tar -zxvf tcl8.6.12-src.tar.gz
    cd tcl8.6.12/unix
    ./configure --prefix=$OUTDIR/dep
    make && make install

    ## Update Makefile to get Tcl library from custom location
    cd $OUTDIR/build
    sed -i "/TCL_FLAGS = -DNO_TCL=1/c\TCL_FLAGS = -I${OUTDIR}/dep/include -DUSE_INTERP_RESULT=1" Makefile
    sed -i "/LIBTCL =  -ldl -lm/c\LIBTCL = ${OUTDIR}/dep/lib/libtcl8.6.so -ldl -lm" Makefile
fi

cd $OUTDIR/build
make
make test
