#!/bin/bash
set -e
trap 'echo "Error occurred at line $LINENO"; exit 1' ERR

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_path="${script_path}/build"
output_path="${script_path}/output"

sdcard_image="${build_path}/sdcard.img"

# 将 u-boot 写入 32K 位置
dd if=${output_path}/u-boot/lckfb-tspi-rk3566.uboot of=$sdcard_image bs=1 seek=32768 conv=notrunc

# 压缩磁盘镜像为 .xz 格式
xz -z ${sdcard_image} -T 0
