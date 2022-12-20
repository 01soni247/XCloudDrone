#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Main
MainPath=$(pwd)
KERNEL_ROOTDIR=$(pwd)
CLANG_ROOTDIR=$(pwd)/clang
ClangPath=${MainClangPath}
MainClangPath=${MainPath}/toolchains/clang
MainClangZipPath=${MainPath}/clang-zip
GCCaPath=${MainPath}toolchains/GCC64
GCCbPath=${MainPath}toolchains/GCC32
MainZipGCCaPath=${MainPath}/GCC64-zip
MainZipGCCbPath=${MainPath}/GCC32-zip


#MakeVersion
VERSION=XQ1.6.5
KERNELNAME=Sea
NAME=Reylin

CloneKernel(){
    git clone --depth=1 https://$githubKey@github.com/Kentanglu/Sea_Kernel-XQ.git -b sea-slmk $DEVICE_CODENAME
}

CloneClang(){
ClangPath=${MainClangZipPath}
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
mkdir $ClangPath
rm -rf $ClangPath/*
wget -q  https://github.com/ZyCromerZ/Clang/releases/download/15.0.0-20220307-release/Clang-15.0.0-20220307.tar.gz -O "Clang-15.0.0-20220307.tar.gz"
tar -xf Clang-15.0.0-20220307.tar.gz -C $ClangPath
}

CloneGcc(){
        git clone https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 10 $GCCaPath --depth=1
        git clone https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 10 $GCCbPath --depth=1
        for64=aarch64-zyc-linux-gnu
        for32=arm-zyc-linux-gnueabi
}

#Main2
DEVICE_CODENAME=lancelot
DEVICE_DEFCONFIG=lancelot_defconfig
IMAGE=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/Image.gz-dtb
DTBO=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/dts/mediatek/mt6768.dtb
export KERNEL_NAME=$(cat "$DEVICE_CODENAME/arch/arm64/configs/$DEVICE_DEFCONFIG" | grep "CONFIG_LOCALVERSION=" | sed 's/CONFIG_LOCALVERSION="-*//g' | sed 's/"*//g' )
export KBUILD_BUILD_USER=Asyanx
export KBUILD_BUILD_HOST=CircleCi
export LOCALVERSION=6.5/Reylin🪷

DATE=$(date +"%F-%S")
START=$(date +"%s")
PATH=${ClangPath}/bin:${GCCaPath}/bin:${GCCbPath}

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# MainChat
MainChat(){
CLANG_VER="$("$ClangPath"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export KBUILD_COMPILER_STRING="$CLANG_VER"
tg_post_msg "<b>KernelCompiler</b>%0AKernel Name : <code>${KERNEL_NAME}</code>%0AKernel Version : <code>${KERVER}</code>%0ABuild Date : <code>${DATE}</code>%0ABuilder Name : <code>${KBUILD_BUILD_USER}</code>%0ABuilder Host : <code>${KBUILD_BUILD_HOST}</code>%0ADevice Defconfig: <code>${DEVICE_DEFCONFIG}</code>%0AClang Version : <code>${KBUILD_COMPILER_STRING}</code>%0AClang Rootdir : <code>${ClangPath}</code>%0AKernel Rootdir : <code>${KERNEL_ROOTDIR}</code>"
}

# Compile
compile(){
tg_post_msg "<b>XCloudDrone:</b><code>Compile $DEVICE_CODENAME DI Mulai</code>"
cd $DEVICE_CODENAME
make -j$(nproc) O=out ARCH=arm64 $DEVICE_DEFCONFIG
make -j$(nproc) ARCH=arm64 O=out \
    CC=${ClangPath}/bin/clang \
    NM=${ClangPath}/bin/llvm-nm \
    AR=${ClangPath}/bin/llvm-ar \
    LD=${ClangPath}/bin/ld.lld \
    CROSS_COMPILE=$for64- \
    CROSS_COMPILE_ARM32=$for32- \
    CLANG_TRIPLE=aarch64-linux-gnu- \

   if ! [ -a "$IMAGE" ]; then
	errorr
	exit 1
   fi
  git clone --depth=1 https://github.com/Kentanglu/AnyKernel3 -b $DEVICE_CODENAME AnyKernel 
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
        -F caption="✅Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | <b>${KBUILD_COMPILER_STRING}</b>"
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
    zip -r9 [$VERSION][$NAME]$DEVICE_CODENAME[$KERNELNAME]-$DATE.zip * -x .git README.md *placeholder
    cd ..
}
CloneKernel
CloneClang
CloneGcc
MainChat
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
