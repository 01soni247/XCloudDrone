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

START=$(date +"%s")

#MakeVersion
VERSION=R0.1
KERNELNAME=Sea
NAME=Azura

CloneKernel(){
    git clone --depth=1 https://$githubKey@github.com/Kentanglu/Sea_Kernel-Selene.git -b twelve $DEVICE_CODENAME
}

CloneFourteenClang(){
ClangPath=${MainClangZipPath}
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
mkdir $ClangPath
rm -rf $ClangPath/*
wget -q  https://github.com/ZyCromerZ/Clang/releases/download/16.0.0-20221118-release/Clang-16.0.0-20221118.tar.gz -O "clang-16.0.0-20221118.tar.gz"
tar -xf clang-16.0.0-20221118.tar.gz -C $ClangPath
}

CloneCompiledGcc(){
        git clone https://github.com/ZyCromerZ/aarch64-linux-android-4.9 $GCCaPath --depth=1
        git clone https://github.com/ZyCromerZ/arm-linux-androideabi-4.9 $GCCbPath --depth=1
        for64=aarch64-linux-android
        for32=arm-linux-androideabi
}

#Main2
DEVICE_CODENAME=selene
DEVICE_DEFCONFIG=selene_defconfig
IMAGE=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/Image.gz-dtb
DTBO=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/dts/mediatek/mt6768.dtb
export KBUILD_BUILD_USER=Asyanx
export KBUILD_BUILD_HOST=CircleCi
export LOCALVERSION=1/Azura🫧
PATH=${ClangPath}/bin:${GCCaPath}/bin:${GCCbPath}/bin:/usr/bin:${PATH}

DATE=$(date +"%F-%S")

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
tg_post_msg "<b>XCloudDrone:</b><code>Compile $DEVICE_CODENAME DI Mulai</code>"
cd $DEVICE_CODENAME
MorePlusPlus=" "
if [[ "$UseGoldBinutils" == "y" ]];then
MorePlusPlus="LD=$for64-ld.gold LDGOLD=$for64-ld.gold HOSTLD=${ClangPath}/bin/ld $MorePlusPlus"
elif [[ "$UseGoldBinutils" == "m" ]];then
MorePlusPlus="LD=$for64-ld LDGOLD=$for64-ld.gold HOSTLD=${ClangPath}/bin/ld $MorePlusPlus"
else
MorePlusPlus="LD=${ClangPath}/bin/ld.lld HOSTLD=${ClangPath}/bin/ld.lld $MorePlusPlus"
fi
echo "MorePlusPlus : $MorePlusPlus"
make -j$(nproc) O=out ARCH=arm64 $DEVICE_DEFCONFIG
make -j$(nproc) ARCH=arm64 O=out \
    LD_LIBRARY_PATH="${ClangPath}/lib:${GCCaPath}/lib:${GCCbPath}/lib:${LD_LIBRARY_PATH}" \
    CC=clang \
    LD_COMPAT=ld.lld \
    CROSS_COMPILE=$for64- \
    CROSS_COMPILE_ARM32=$for32- \
    CLANG_TRIPLE=aarch64-linux-gnu- ${MorePlusPlus}

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
        -F caption="✨Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b>✨"
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
    zip -r9 [$VERSION]$DEVICE_CODENAME[$NAME][R-OSS][$KERNELNAME]-$DATE.zip * -x .git README.md *placeholder
    cd ..
}
CloneKernel
CloneFourteenClang
CloneCompiledGcc
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
