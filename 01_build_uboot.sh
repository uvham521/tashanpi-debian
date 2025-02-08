#!/bin/bash
set -e
trap 'echo "Error occurred at line $LINENO"; exit 1' ERR

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_path="${script_path}/build"
output_path="${script_path}/output"

export CROSS_COMPILE=aarch64-linux-gnu-
export BL31=${script_path}/downloads/rkbin/rk3568_bl31_v1.44.elf
export ROCKCHIP_TPL=${script_path}/downloads/rkbin/rk3566_ddr_1056MHz_v1.23.bin

cd ${build_path}/u-boot

make distclean
make lckfb-tspi-rk3566_defconfig
make -j`getconf _NPROCESSORS_ONLN`

rm -rf ${output_path}/u-boot
mkdir -p ${output_path}/u-boot

make savedefconfig
mv defconfig ${output_path}/u-boot/lckfb-tspi-rk3566_defconfig
mv u-boot-rockchip.bin ${output_path}/u-boot/lckfb-tspi-rk3566.uboot
