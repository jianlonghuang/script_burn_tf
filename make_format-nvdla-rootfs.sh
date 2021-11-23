#!/bin/bash
## Copy from u-sdk/Makefile
## Usage: $0 /dev/sdb
set -e

uboot=$PWD/u-boot.bin
vfat_image=$PWD/hifive-unleashed-vfat.part
buildroot_rootfs_ext=$PWD/rootfs.ext4

# Relevant partition type codes
BBL=2E54B353-1271-4842-806F-E436D6AF6985
VFAT=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
LINUX=0FC63DAF-8483-4772-8E79-3D69D8477DE4
#FSBL=5B193300-FC78-40CD-8002-E86C45580B47
UBOOT=5B193300-FC78-40CD-8002-E86C45580B47
UBOOTENV=a09354ac-cd63-11e8-9aff-70b3d592f0fa
UBOOTDTB=070dd1a8-cd64-11e8-aa3d-70b3d592f0fa
UBOOTFIT=04ffcafa-cd65-11e8-b974-70b3d592f0fa

let VFAT_START=4096
let VFAT_END=270335
let VFAT_SIZE=266239
let UBOOT_START=270336
let UBOOT_END=272383
let UBOOT_SIZE=2047
let UENV_START=272384
let UENV_END=274431

let ROOT_BEGIN=272384
# default size: 20GB
let ROOT_CLUSTER_NUM=20*1024*1024*1024/512
let ROOT_END=$ROOT_BEGIN+$ROOT_CLUSTER_NUM

DISK=$1

#### make format-nvdla-disk #####
if [ ! -b $DISK ]; then
    echo "$DISK is not exist or not block device"
    echo "Usage: $0 /dev/sdb"
    exit 1
fi

/sbin/sgdisk --clear  \
    --new=1:$VFAT_START:$VFAT_END  --change-name=1:"Vfat Boot"  --typecode=1:$VFAT   \
    --new=2:$UBOOT_START:$UBOOT_END   --change-name=2:uboot --typecode=2:$UBOOT \
    --new=3:$ROOT_BEGIN:0 --change-name=3:root  --typecode=3:$LINUX \
    $DISK
/sbin/partprobe

#if [ $? -eq 0 ]; then
#fi

sleep 1
if [ -b ${DISK}p1 ]; then
    PART1=${DISK}p1
    PART2=${DISK}p2
    PART3=${DISK}p3
elif [ -b ${DISK}s1 ]; then
    PART1=${DISK}s1
    PART2=${DISK}s2
    PART3=${DISK}s3
elif [ -b ${DISK}1 ]; then
    PART1=${DISK}1
    PART2=${DISK}2
    PART3=${DISK}3
else
    echo "Error: Could not find bootloader partition for $DISK"
    exit 1
fi

dd if=$uboot of=$PART2 bs=4096
dd if=$vfat_image of=$PART1 bs=4096


#### make format-nvdla-rootfs #####
echo "Done setting up basic initramfs boot. We will now try to install"
echo "a Debian snapshot to the Linux partition, which requires sudo"
echo "you can safely cancel here"
/sbin/mke2fs -t ext4 $PART3
mkdir -p tmp-mnt
mkdir -p tmp-rootfs
sudo mount $PART3 tmp-mnt && \
    sudo mount -o loop $buildroot_rootfs_ext tmp-rootfs && \
    sudo cp -fr tmp-rootfs/* tmp-mnt/
sudo umount tmp-mnt
sudo umount tmp-rootfs
