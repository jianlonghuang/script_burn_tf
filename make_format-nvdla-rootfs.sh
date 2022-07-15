#!/bin/bash
## Copy from u-sdk/Makefile
## Usage: $0 /dev/sdb
set -e

uboot_fit=$PWD/visionfive2_fw_payload.img
vfat_image=$PWD/starfive-visionfive2-vfat.part
buildroot_rootfs_ext=$PWD/rootfs.ext4

# Relevant partition type codes
SPL=2E54B353-1271-4842-806F-E436D6AF6985
VFAT=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
LINUX=0FC63DAF-8483-4772-8E79-3D69D8477DE4
UBOOT=5B193300-FC78-40CD-8002-E86C45580B47
UBOOTENV=a09354ac-cd63-11e8-9aff-70b3d592f0fa
UBOOTDTB=070dd1a8-cd64-11e8-aa3d-70b3d592f0fa
UBOOTFIT=04ffcafa-cd65-11e8-b974-70b3d592f0fa

let SPL_START=2048
let SPL_END=6143
let UBOOT_START=6144
let UBOOT_END=16383
let UBOOT_SIZE=$UBOOT_END-$UBOOT_START+1
let VFAT_START=16384
let VFAT_END=614399
let VFAT_SIZE=$VFAT_END-$VFAT_START+1
let ROOT_START=614400


DISK=$1

#### make format-nvdla-disk #####
if [ ! -b $DISK ]; then
    echo "$DISK is not exist or not block device"
    echo "Usage: $0 /dev/sdb"
    exit 1
fi

sudo /sbin/sgdisk --clear  \
	--new=1:$SPL_START:$SPL_END     --change-name=1:"spl"   --typecode=1:$SPL   \
	--new=2:$UBOOT_START:$UBOOT_END --change-name=2:"uboot" --typecode=2:$UBOOT \
	--new=3:$VFAT_START:$VFAT_END   --change-name=3:"image" --typecode=3:$VFAT  \
	--new=4:$ROOT_START:0             --change-name=4:"root"  --typecode=4:$LINUX \
	$DISK
sudo /sbin/partprobe
sleep 1

if [ -b ${DISK}p1 ]; then
    PART1=${DISK}p1
    PART2=${DISK}p2
    PART3=${DISK}p3
    PART4=${DISK}p4
elif [ -b ${DISK}s1 ]; then
    PART1=${DISK}s1
    PART2=${DISK}s2
    PART3=${DISK}s3
    PART4=${DISK}s4
elif [ -b ${DISK}1 ]; then
    PART1=${DISK}1
    PART2=${DISK}2
    PART3=${DISK}3
    PART4=${DISK}4
else
    echo "Error: Could not find bootloader partition for $DISK"
    exit 1
fi

sudo dd if=$uboot_fit  of=$PART2 bs=4096
sudo dd if=$vfat_image of=$PART3 bs=4096
sync
sleep 1

echo "Done setting up basic initramfs boot. We will now try to install"
echo "a Debian snapshot to the Linux partition, which requires sudo"
echo "you can safely cancel here"
sudo /sbin/mke2fs -t ext4 $PART4
mkdir -p tmp-mnt
mkdir -p tmp-rootfs
sudo mount $PART4 tmp-mnt && \
	sudo mount -o loop $buildroot_rootfs_ext tmp-rootfs&& \
	sudo cp -fr tmp-rootfs/* tmp-mnt/
sync
sleep 1
sudo umount tmp-mnt
sudo umount tmp-rootfs
rmdir tmp-mnt
rmdir tmp-rootfs

