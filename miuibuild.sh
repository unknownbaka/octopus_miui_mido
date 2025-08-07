#!/bin/bash
date=`date +"%Y%m%d-%H%M"`
DATE=`date +"%Y%m%d%H%M"`

BUILD_START=$(date +"%s")
# Coloring
blue='\033[0;34m'
cyan='\033[0;36m'
purple='\e[0;35m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'


export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="unknownbaka" # Build Host
export KBUILD_BUILD_HOST="Ubuntu" # Build Name
export CONFIG_FILE="octopus_defconfig"
export KERNEL_DIR=$(pwd)
export CROSS_COMPILE="${KERNEL_DIR}/../aarch64-linux-android-4.9/bin/aarch64-linux-android-"
export PATH=$PATH:${CROSS_COMPILE}
export OUT_DIR="${KERNEL_DIR}/out/"
export BUILD_DIR="${KERNEL_DIR}/Builds"
export ANY_KERNEL_DIR="${KERNEL_DIR}/AnyKernel3"
export ZIP_NAME="miui-octopus-${DATE}.zip"
export IMAGE="${OUT_DIR}/arch/arm64/boot/Image.gz-dtb";
export LD_LIBRARY_PATH="$CROSS_COMPILE/../lib:$PATH"
export STRIP_KO="${KERNEL_DIR}/../aarch64-linux-android-4.9/aarch64-linux-android/bin/strip"

make_defconfig() {
	make O=${OUT_DIR} $CONFIG_FILE
}

compile() {
    echo "**** Build Start ****"
	make  O=${OUT_DIR} -j$(nproc --all)
}

zipit () {
    echo "**** Copying Image ****"
    cp ${OUT_DIR}arch/arm64/boot/Image.gz-dtb ${ANY_KERNEL_DIR}/

    echo "**** Copying Modules for MIUI ROM ****"
    ${STRIP_KO} -g ${OUT_DIR}/drivers/staging/prima/wlan.ko
    mkdir -p ${ANY_KERNEL_DIR}/modules/system/lib/modules/pronto
    cp ${OUT_DIR}/drivers/staging/prima/wlan.ko ${ANY_KERNEL_DIR}/modules/system/lib/modules/pronto/pronto_wlan.ko
    cd ${ANY_KERNEL_DIR}/

    echo "**** Zipping ****"
    make
    if [ ! -d ${BUILD_DIR} ]; then
        mkdir ${BUILD_DIR}
    fi
    mv ${ANY_KERNEL_DIR}/Kernel.zip ${BUILD_DIR}/${ZIP_NAME}
    rm ${ANY_KERNEL_DIR}/Image.gz-dtb
    rm -rf ${ANY_KERNEL_DIR}/modules
}

make_defconfig
compile
if [ $? -eq 0 ]; then
    zipit
else
    cd ${KERNEL_DIR}
    exit 1
fi
cd ${KERNEL_DIR}

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."