#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

	# Fix the "multiple definition of yylloc" error.
	sed -i 's/^YYLTYPE yylloc;/extern YYLTYPE yylloc;/' ./scripts/dtc/dtc-lexer.l

    # TODO: Add your kernel build steps here
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
	cp  ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/Image
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs/{bin,dev,etc,home,lib,lib64,proc,sbin,sys,tmp,usr,var}
mkdir -p ${OUTDIR}/rootfs/usr/{bin,lib,sbin}
mkdir -p ${OUTDIR}/var/log
mkdir -p ${OUTDIR}/rootfs/home/conf # Needed for the automated tests.
mkdir -p ${OUTDIR}/rootfs/conf      # Needed for the automated tests.

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
	git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
	make distclean
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
	sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
sudo "PATH=$PATH" make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

#echo "Library dependencies"
#${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
#${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp -avL ${SYSROOT}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/libc.so.6
cp -avL ${SYSROOT}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/ld-linux-aarch64.so.1

# TODO: Make device nodes
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/console c 5   1
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null    c 1   3

# TODO: Clean and build the writer utility
cd "$FINDER_APP_DIR"
CROSS_COMPILE="$CROSS_COMPILE" make
cp writer ${OUTDIR}/rootfs/home/


# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp ${FINDER_APP_DIR}/../conf/username.txt   ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/../conf/username.txt   ${OUTDIR}/rootfs/home/conf/
cp ${FINDER_APP_DIR}/../conf/assignment.txt ${OUTDIR}/rootfs/conf/
cp ${FINDER_APP_DIR}/finder.sh              ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/finder-test.sh         ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/autorun-qemu.sh        ${OUTDIR}/rootfs/home/

# Fix finder.sh.
sed -i 's/bash/sh/' ${OUTDIR}/rootfs/home/finder.sh

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs/

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
sudo sh -c "find . -print0 | cpio --null --create --verbose --format=newc | gzip > ${OUTDIR}/initramfs.cpio.gz"
