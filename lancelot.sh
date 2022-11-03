#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Main
MainPath=$(pwd)
MainClangPath=${MainPath}/toolchains/clang
MainClangZipPath=${MainPath}/clang-zip
ClangPath=${MainClangPath}
GCCaPath=${MainPath}toolchains/GCC64
GCCbPath=${MainPath}toolchains/GCC32
MainZipGCCaPath=${MainPath}/GCC64-zip
MainZipGCCbPath=${MainPath}/GCC32-zip

#Main2
VERSION=XQ1.6Plus
KERNEL_NAME=Sea
export LOCALVERSION=🦭
KERNEL_ROOTDIR=$(pwd)
DEVICE_DEFCONFIG=lancelot_defconfig
DEVICE_CODENAME=Lancelot
export KERNEL_NAME=$(cat "arch/arm64/configs/$DEVICE_DEFCONFIG" | grep "CONFIG_LOCALVERSION=" | sed 's/CONFIG_LOCALVERSION="-*//g' | sed 's/"*//g' )
CLANG_ROOTDIR=$(pwd)/clang
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$CLANG_ROOTDIR"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
IMAGE=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/Image.gz-dtb
DTBO=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/dts/mediatek/mt6768.dtb
export KBUILD_BUILD_USER=Asyanx
export KBUILD_BUILD_HOST=CircleCi

DATE=$(date +"%F-%S")
START=$(date +"%s")

#Clone Source
clone(){
git clone --depth=1 https://$githubKey@github.com/Kentanglu/Sea-XQ.git -b main $DEVICE_CODENAME
cd $DEVICE_CODENAME
}

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# Massage
tg_post_msg "<b>XCloudDrone</b>%0AKernel Name : <code>${KERNEL_NAME}</code>%0AKernel Version : <code>${KERVER}</code>%0ABuild Date : <code>${DATE}</code>%0ABuilder Name : <code>${KBUILD_BUILD_USER}</code>%0ABuilder Host : <code>${KBUILD_BUILD_HOST}</code>%0ADevice Defconfig: <code>${DEVICE_DEFCONFIG}</code>%0AClang Version : <code>${KBUILD_COMPILER_STRING}</code>%0AClang Rootdir : <code>${CLANG_ROOTDIR}</code>%0AKernel Rootdir : <code>${KERNEL_ROOTDIR}</code>"


# Compile
compile(){
tg_post_msg "<b>XCloudDrone:</b><code>Compile R9 DI Mulai</code>"
PATH="${PATH}:$(pwd)/clang/bin"
make -j$(nproc) O=out ARCH=arm64 $DEVICE_DEFCONFIG
make -j$(nproc) ARCH=arm64 O=out \
    CC=${CLANG_ROOTDIR}/bin/clang \
    LD=${CLANG_ROOTDIR}/bin/ld.lld \
    NM=${CLANG_ROOTDIR}/bin/llvm-nm \
    STRIP=${CLANG_ROOTDIR}/bin/llvm-strip \
    OBJCOPY=${CLANG_ROOTDIR}/bin/llvm-objcopy \
    OBJDUMP=${CLANG_ROOTDIR}/bin/llvm-objdump \
    CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi- \
    2>&1 | tee error.log

   if ! [ -a "$IMAGE" ]; then
	errorr
	exit 1
   fi
  git clone --depth=1 https://github.com/kentanglu/AnyKernel -b $DEVICE_CODENAME AnyKernel 
	cp $IMAGE AnyKernel
}

# Push kernel to channel
function push() {
tg_post_msg "Mengirim Kernel $DEVICE_CODENAME..."
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@"$ZIP" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F parse_mode=markdown https://api.telegram.org/bot$TG_TOKEN/sendDocument \
        -F caption="✨Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | <b>${KBUILD_COMPILER_STRING}</b>✨"
}

# Fin Error
function errorr() {
tg_post_msg "Terjadi Error Dalam Proses Compile❌"
    cd out
    LOG=$(echo error.log)
    curl -d document=@"$LOG" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d parse_mode=markdown https://api.telegram.org/bot$TG_TOKEN/sendDocument \
        -d caption="Build throw an error(s)"
    exit 1
}

# Zipping
function zipping() {
tg_post_msg "Proses Zipping Kernel $DEVICE_CODENAME..."
    cd AnyKernel || exit 1
    zip -r9 [$VERSION]Lancelot[Keysha][$KERNEL_NAME]-$DATE.zip * -x .git README.md *placeholder
    cd ..
}
clone
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
