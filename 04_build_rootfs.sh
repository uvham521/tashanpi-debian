#!/bin/bash
set -e
trap 'echo "Error occurred at line $LINENO"; exit 1' ERR

# 检测是否以root权限执行
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (using sudo)." 
    exit 1
fi

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_path="${script_path}/build"
output_path="${script_path}/output"

# Exports
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Mount our loopback for the image
disk_loop_dev=$(losetup -f -P --show ${build_path}/sdcard.img)

# Now format our partitions since were mounted as a loop device
mkfs.fat -F 32 -n BOOT ${disk_loop_dev}p1
mkfs.ext4 -L Debian ${disk_loop_dev}p2

# Setup mounts!
mkdir -p ${build_path}/rootfs
mount -t ext4 ${disk_loop_dev}p2 ${build_path}/rootfs
mkdir -p ${build_path}/rootfs/boot
mount -t vfat ${disk_loop_dev}p1 ${build_path}/rootfs/boot

# CD into our rootfs mount, and starts the fun!
cd ${build_path}/rootfs
debootstrap --no-check-gpg --foreign --arch=arm64 --include=apt-transport-https bookworm ${build_path}/rootfs http://mirrors.aliyun.com/debian
cp /usr/bin/qemu-aarch64-static usr/bin/
chroot ${build_path}/rootfs /debootstrap/debootstrap --second-stage

# Copy over our overlay if we have one
if [[ -d ${script_path}/overlay/rootfs/ ]]; then
	echo "Applying ${fs_overlay_dir} overlay"
	cp -R ${script_path}/overlay/rootfs/* ./
fi

# Hostname
echo "debian" > ${build_path}/rootfs/etc/hostname
echo "127.0.1.1	debian" >> ${build_path}/rootfs/etc/hosts

# Populate fstab with UUIDs
echo "UUID=$(findmnt -no uuid ${build_path}/rootfs)  /  ext4  discard,errors=remount-ro  0  0" > ${build_path}/rootfs/etc/fstab
echo "UUID=$(findmnt -no uuid ${build_path}/rootfs/boot)  /boot  vfat  defaults  0  1" >> ${build_path}/rootfs/etc/fstab

# Console settings
echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
" > ${build_path}/rootfs/debconf.set

# Copy over kernel goodies
cp -r ${output_path}/kernel ${build_path}/rootfs/root/

# Do mounts for grub
mount --bind /dev ${build_path}/rootfs/dev
mount --bind /sys ${build_path}/rootfs/sys
mount --bind /proc ${build_path}/rootfs/proc

# Kick off bash setup script within chroot
chroot ${build_path}/rootfs bash /bootstrap
rm ${build_path}/rootfs/bootstrap

# Cleanup mounts for grub
umount ${build_path}/rootfs/proc
umount ${build_path}/rootfs/sys
umount ${build_path}/rootfs/dev

# CD out before cleanup!
cd ${build_path}

# Final cleanup
rm ${build_path}/rootfs/usr/bin/qemu-aarch64-static
umount ${build_path}/rootfs/boot
umount ${build_path}/rootfs
losetup -d ${disk_loop_dev}
rm -rf ${build_path}/rootfs
