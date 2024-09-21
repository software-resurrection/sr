## Compiling and testing numpy-1.1.0 in a modern platform. This has been
## tested in the following platform.
##
## Operating System: Debian GNU/Linux 12 (bookworm)
## Hardware: Intel(R) Core(TM) i9-9980HK CPU @ 2.40GHz, 16 cores, x86_64, Little Endian
##
## Author : Abhishek Dutta <https://abhishekdutta.org>
## Date   : 21-Sep-2022
##
## Usage: ./apply-patch.sh OUTDIR
## e.g. ./apply-patch.sh /tmp/numpy/

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
## Download source for numpy-1.1.0
##
if [ ! -f "${OUTDIR}/numpy-1.1.0.tar.gz" ]; then
    cd $OUTDIR
    wget https://sourceforge.net/projects/numpy/files/NumPy/1.1.0/numpy-1.1.0.tar.gz/download \
      -O numpy-1.1.0.tar.gz
    echo "c36451e05251599294abfefa386835300e2066d5 *numpy-1.1.0.tar.gz" | sha1sum -c -
    tar -zxvf numpy-1.1.0.tar.gz
    cd $OUTDIR/numpy-1.1.0/
    git init .
    git add .
    git commit -m "original source for numpy-1.1.0 released on 28-May-2008"
fi

##
## Apply patches to numpy-1.1.0
##
GIT_REV_COUNT=`git -C ${OUTDIR}/numpy-1.1.0/ rev-list --count HEAD`

if [[ $GIT_REV_COUNT -eq 1 ]]; then
    cd "${OUTDIR}/numpy-1.1.0"

    git am $PATCHDIR/0001-fix-for-NameError-global-name-copy-is-not-defined.patch
    git am $PATCHDIR/0002-fix-for-NameError-global-name-DistutilsExecError.patch
    git am $PATCHDIR/0003-fix-for-static-declaration-of-acosh-follows-non-static.patch
    git am $PATCHDIR/0004-remove-PyOS_ascii_strtod-which-has-been-deprecated.patch
    git am $PATCHDIR/0005-fix-logical-error-which-failed-to-add-space-after-sep.patch
fi

##
## Build patched version of numpy-1.1.0
##
if [ -d "${OUTDIR}/numpy-1.1.0" ]; then
    cd $OUTDIR/numpy-1.1.0
    python2 setup.py build
    sudo python2 setup.py install
fi

##
## Run tests
##

if [ -d "${OUTDIR}/numpy-1.1.0/build/" ]; then
    cd $OUTDIR
    python2 -c "import numpy; numpy.test(verbosity=2)"
fi
