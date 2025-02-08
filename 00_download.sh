#!/bin/bash
set -e
trap 'echo "Error occurred at line $LINENO"; exit 1' ERR

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_path="${script_path}/build"

mkdir -p $build_path

# 判断u-boot文件夹是否存在
if [ ! -d "${build_path}/u-boot" ]; then
    git clone --depth=1 --branch=rk3566 https://github.com/BigfootACA/u-boot "${build_path}/u-boot"
else
    echo "u-boot 目录已存在, 跳过拉取"
fi

# 判断linux文件夹是否存在
if [ ! -d "${build_path}/linux" ]; then
    git clone --depth=1 --branch=rk3566-v6.8 https://github.com/BigfootACA/linux "${build_path}/linux"
else
    echo "linux 目录已存在, 跳过拉取"
fi
