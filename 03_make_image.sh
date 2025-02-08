#!/bin/bash
set -e
trap 'echo "Error occurred at line $LINENO"; exit 1' ERR

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_path="${script_path}/build"
output_path="${script_path}/output"

sdcard_image="${build_path}/sdcard.img"
compressed_image="${sdcard_image}.xz"  # 生成的压缩文件名

# 删除旧的镜像文件和压缩文件
rm -f ${sdcard_image} ${compressed_image}

# 创建空的磁盘镜像
truncate -s 3584M $sdcard_image  # 3.5GB = 3584MB
parted -s $sdcard_image mklabel msdos

# 创建 boot 分区 (FAT32, 0xC)
parted -s $sdcard_image mkpart primary fat32 16M 128M
parted -s $sdcard_image set 1 boot on

# 创建 rootfs 分区 (Linux, 0x83)
parted -s $sdcard_image mkpart primary ext4 128M 100%
