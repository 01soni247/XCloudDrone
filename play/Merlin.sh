#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Main
export LOCALVERSION=🐙
VERSION=XQ1.4-Bubble
MainPath=$(pwd)
MainClangPath=${MainPath}/clang
MainClangZipPath=${MainPath}/clang-zip
ClangPath=${MainClangZipPath}
GCCaPath=${MainPath}/GCC64
GCCbPath=${MainPath}/GCC32
MainZipGCCaPath=${MainPath}/GCC64-zip
MainZipGCCbPath=${MainPath}/GCC32-zip
CLANG_ROOTDIR=$(pwd)/clang
KERNELNAME=Sea
export KBUILD_BUILD_USER=Hallo
export KBUILD_BUILD_HOST=SHIROs
IMAGE=$(pwd)/merlin/out/arch/arm64/boot/Image.gz-dtb
DTBO=$(pwd)/merlin/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/merlin/out/arch/arm64/boot/dts/mediatek/mt6768.dtb
DEVICE_CODENAME=Merlinx

DATE=$(date +"%F-%S")
START=$(date +"%s")
PATH="${PATH}:$(pwd)/clang/bin"

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# Compile
compile(){
tg_post_msg "<b>xKernelCompiler:</b><code>Compile Kernel DI Mulai</code>"
cd merlin
make -j$(nproc) O=out ARCH=arm64 merlin_defconfig
make -j$(nproc) ARCH=arm64 O=out \
    CC=${CLANG_ROOTDIR}/bin/clang \
    LD=${CLANG_ROOTDIR}/bin/ld.lld \
    NM=${CLANG_ROOTDIR}/bin/llvm-nm \
    STRIP=${CLANG_ROOTDIR}/bin/llvm-strip \
    OBJCOPY=${CLANG_ROOTDIR}/bin/llvm-objcopy \
    OBJDUMP=${CLANG_ROOTDIR}/bin/llvm-objdump \
    CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi
  git clone --depth=1 https://github.com/kentanglu/AnyKernel -b master-merlin AnyKernel 
	cp $IMAGE AnyKernel
}

# Push kernel to channel
function push() {
tg_post_msg "Sending file..."
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@"$ZIP" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F parse_mode=markdown https://api.telegram.org/bot$TG_TOKEN/sendDocument \
        -F caption="✨Compile took $(($DIFF / 60)) Minute(s) and $(($DIFF % 60)) second(s). | For $DEVICE_CODENAME | ${DATE}✨"
}

# Fin Error
function finerr() {
    curl -d document=@"out/error.log" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d parse_mode=markdown https://api.telegram.org/bot$TG_TOKEN/sendDocument \
        -d caption="Build throw an error(s)"
    exit 1
}

# Zipping
function zipping() {
tg_post_msg "Zipping Kernel..."
    cd AnyKernel || exit 1
    zip -r9 [$VERSION]Merlinx[$KERNELNAME]-$DATE.zip * -x .git README.md *placeholder
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push