#!/bin/bash
set -e
trap 'echo "Error occurred at line $LINENO"; exit 1' ERR

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_path="${script_path}/build"
output_path="${script_path}/output"

export ARCH=arm64
export GCC_COLORS=auto
export CROSS_COMPILE=aarch64-linux-gnu-

cd ${build_path}/linux

make lckfb-tspi-rk3566_defconfig
make -j`getconf _NPROCESSORS_ONLN` EXTRAVERSION=-$(date +%Y%m%d-%H%M%S) bindeb-pkg dtbs

# Remove the debug kernel (were too cool for that)
rm ${build_path}/linux-image-*-dbg_*.deb

# Move our debs to the kernel dir
mv ${build_path}/linux-*.deb ${output_path}/kernel
