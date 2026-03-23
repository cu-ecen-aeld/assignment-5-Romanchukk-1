#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

# In time when i do this assignment, busybox.net waws not allowed, so i moved to mirror on gtihub"
BUSYBOX_MIRROR_REPO=https://github.com/mirror/busybox.git

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

if [ ! -d "${OUTDIR}" ]; then
	mkdir -p ${OUTDIR}
fi

if [ -d "${OUTDIR}" ]; then
	cd "${OUTDIR}"
else
	echo "Failed to create output directory"
	exit 1
fi

if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

	 # TODO: Add your kernel build steps here
	make ARCH=${ARCH} CROSS_COMPLIE=${CROSS_COMPILE} mrproper
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
	make ARCH=${ARCH} -j$(nproc) CROSS_COMPILE=${CROSS_COMPILE} all
fi

if [ ! -e ${OUTDIR}/Image ]; then
	cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/Image"
fi

echo "Adding the Image in outdir"

# Temporary exit
# echo "Temporary exit from script"
# exit 0

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p "${OUTDIR}/rootfs"
cd "${OUTDIR}/rootfs"
mkdir -p "bin" "dev" "etc" "home" "lib" "lib64" "proc" "sbin" "sys" "tmp" "usr" "var"
mkdir -p "home/conf"
mkdir -p "usr/bin" "usr/lib" "usr/sbin"
mkdir -p "var/log"

# Temporary exit 2
# echo "Temporary exit from script"
# exit 0

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone ${BUSYBOX_MIRROR_REPO}
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# TODO: Make and install busybox
if [ ! -e "${OUTDIR}/rootfs/bin/busybox" ]; then
	make distclean
	make defconfig
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
	make -j$(nproc) ARCH=${ARCH} CONFIG_PREFIX="${OUTDIR}/rootfs" CROSS_COMPILE=${CROSS_COMPILE} install
fi

echo "Library dependencies"
cd "${OUTDIR}"

${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | grep "program interpreter"
${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | grep "Shared library"

# TODO: Add library dependencies to rootfs
INTEPRETER=$(find $(${CROSS_COMPILE}gcc -print-sysroot) -name "ld-linux-aarch64.so.1")

cp ${INTEPRETER} "${OUTDIR}/rootfs/lib"

LIBOBJ=$(find $(${CROSS_COMPILE}gcc -print-sysroot) -name "libm.so.6")
cp ${LIBOBJ} "${OUTDIR}/rootfs/lib64"

LIBOBJ=$(find $(${CROSS_COMPILE}gcc -print-sysroot) -name "libresolv.so.2")
cp ${LIBOBJ} "${OUTDIR}/rootfs/lib64"

LIBOBJ=$(find $(${CROSS_COMPILE}gcc -print-sysroot) -name "libc.so.6")
cp ${LIBOBJ} "${OUTDIR}/rootfs/lib64"

# TODO: Make device nodes
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/null"    c 1 3
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/zero"    c 1 5
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/random"  c 1 8
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/urandom" c 1 9
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/tty"     c 5 0
sudo mknod -m 600 "${OUTDIR}/rootfs/dev/console" c 5 1

# TODO: Clean and build the writer utility
cd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp "${FINDER_APP_DIR}/writer" "${OUTDIR}/rootfs/home/writer"
cp "${FINDER_APP_DIR}/writer.sh" "${OUTDIR}/rootfs/home/writer.sh"

cp "${FINDER_APP_DIR}/finder.sh" "${OUTDIR}/rootfs/home/finder.sh"
cp "${FINDER_APP_DIR}/finder-test.sh" "${OUTDIR}/rootfs/home/finder-test.sh"

cp "${FINDER_APP_DIR}/conf/assignment.txt" "${OUTDIR}/rootfs/home/conf/assignment.txt"
cp "${FINDER_APP_DIR}/conf/username.txt" "${OUTDIR}/rootfs/home/conf/username.txt"

cp "${FINDER_APP_DIR}/autorun-qemu.sh" "${OUTDIR}/rootfs/home/autorun-qemu.sh"

# TODO: Chown the root directory
sudo chown -R root:root "${OUTDIR}/rootfs"

# TODO: Create initramfs.cpio.gz
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio"
cd "${OUTDIR}"
gzip -f initramfs.cpio
