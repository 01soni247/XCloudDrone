#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Main
export LOCALVERSION=🪨
VERSION=XQ1.6-Batu
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
export KBUILD_BUILD_USER=LopeYu
export KBUILD_BUILD_HOST=Kamuh
IMAGEL=$(pwd)/lancelot/out/arch/arm64/boot/Image.gz-dtb
DTBOl=$(pwd)/lancelot/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/lancelot/out/arch/arm64/boot/dts/mediatek/mt6768.dtb
DEVICE_CODENAME=Lancelot

DATE=$(date +"%F-%S")
START=$(date +"%s")

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
git clone --depth=1 https://gitlab.com/RyuujiX/atom-x-clang clang
git clone --depth=1 https://$githubKey@github.com/Kentanglu/Sea-XQ.git lancelot
PATH="${PATH}:$(pwd)/clang/bin"
cd lancelot
tg_post_msg "<b>xKernelCompiler:</b><code>Compile Kernel Lancelot DI Mulai</code>"
make -j$(nproc) O=out ARCH=arm64 lancelot_defconfig
make -j$(nproc) ARCH=arm64 O=out \
    CC=${CLANG_ROOTDIR}/bin/clang \
    LD=${CLANG_ROOTDIR}/bin/ld.lld \
    NM=${CLANG_ROOTDIR}/bin/llvm-nm \
    STRIP=${CLANG_ROOTDIR}/bin/llvm-strip \
    OBJCOPY=${CLANG_ROOTDIR}/bin/llvm-objcopy \
    OBJDUMP=${CLANG_ROOTDIR}/bin/llvm-objdump \
    CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-

   if ! [ -a "$IMAGEL" ]; then
	finerr
	exit 1
   fi
  git clone --depth=1 https://github.com/kentanglu/AnyKernel -b master-lancelot AnyKernel 
	cp $IMAGEL AnyKernel
}

# Push kernel to channel
function push() {
tg_post_msg "Sending file Lancelot..."
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
tg_post_msg "Zipping Kernel Lancelot..."
    cd AnyKernel || exit 1
    zip -r9 [$VERSION]Lancelot[$KERNELNAME]-$DATE.zip * -x .git README.md *placeholder
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
