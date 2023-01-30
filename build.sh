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
VERSION=XQ1.6
KERNELNAME=Sea
TYPE=Q-OSS
CODENAME=RedSquid
UseZyCLLVM="n"
UseGCCLLVM="n"
UseGoldBinutils="n"
UseOBJCOPYBinutils="n"
TypeBuilder="n"

CloneKernel(){
    git clone --depth=1 https://$githubKey@github.com/Kentanglu/Sea_Kernel-XQ.git -b sea-slmk $DEVICE_CODENAME
}

CloneClang(){
ClangPath=${MainClangZipPath}
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
mkdir $ClangPath
rm -rf $ClangPath/*
wget https://github.com/ZyCromerZ/Clang/releases/download/17.0.0-20230128-release/Clang-17.0.0-20230128.tar.gz -O "Clang-17.0.0-20230128.tar.gz"
tar -xf Clang-17.0.0-20230128.tar.gz -C $ClangPath
}

CloneGcc(){
        git clone https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 13 $GCCaPath --depth=1
        git clone https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 13 $GCCbPath --depth=1
        for64=aarch64-zyc-linux-gnu
        for32=arm-zyc-linux-gnueabi
}

#Main2
DEVICE_CODENAME=lancelot
DEVICE_DEFCONFIG=lancelot_defconfig
IMAGE=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/Image.gz-dtb
DTBO=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/dts/mediatek/mt6768.dtb
export LOCALVERSION=/RedSquid🐙
export KBUILD_BUILD_USER=Asyanx
export KBUILD_BUILD_HOST=CircleCi

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
CLANG_VER="$("$ClangPath"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$ClangPath"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
tg_post_msg "<b>KernelCompiler</b>%0AKernel Name : <code>${KERNELNAME}</code>%0AKernel Version : <code>${VERSION}</code>%0ABuild Date : <code>${DATE}</code>%0ABuilder Name : <code>${KBUILD_BUILD_USER}</code>%0ABuilder Host : <code>${KBUILD_BUILD_HOST}</code>%0ADevice Defconfig: <code>${DEVICE_DEFCONFIG}</code>%0AClang Version : <code>${KBUILD_COMPILER_STRING}</code>%0AClang Rootdir : <code>${ClangPath}</code>%0AKernel Rootdir : <code>${KERNEL_ROOTDIR}</code>"
tg_post_msg "<b>XCloudDrone:</b><code>Compile $DEVICE_CODENAME DI Mulai</code>"
cd $DEVICE_CODENAME
    MorePlusPlus=" "
    PrefixDir=""
    if [[ "$UseZyCLLVM" == "y" ]];then
        PrefixDir="${MainClangZipPath}-zyc/bin/"
    elif [[ "$UseGCCLLVM" == "y" ]];then
        PrefixDir="${GCCaPath}/bin/"
    else
        PrefixDir="${ClangPath}/bin/"
    fi
    if [[ "$TypeBuilder" != *"SDClang"* ]];then
        MorePlusPlus="HOSTCC=clang HOSTCXX=clang++"
    else
        MorePlusPlus="HOSTCC=gcc HOSTCXX=g++"
    fi
    if [[ "$UseGoldBinutils" == "y" ]];then
        MorePlusPlus="LD=$for64-ld.gold LDGOLD=$for64-ld.gold HOSTLD=${PrefixDir}ld $MorePlusPlus"
        [[ "$UseGCCLLVM" == "y" ]] && MorePlusPlus="LD_COMPAT=$for32-ld.gold $MorePlusPlus"
    elif [[ "$UseGoldBinutils" == "m" ]];then
        MorePlusPlus="LD=$for64-ld LDGOLD=$for64-ld.gold HOSTLD=${PrefixDir}ld $MorePlusPlus"
        [[ "$UseGCCLLVM" == "y" ]] && MorePlusPlus="LD_COMPAT=$for32-ld $MorePlusPlus"
    else
        MorePlusPlus="LD=${PrefixDir}ld.lld HOSTLD=${PrefixDir}ld.lld $MorePlusPlus"
        [[ "$UseGCCLLVM" == "y" ]] && MorePlusPlus="LD_COMPAT=$for32-ld.lld $MorePlusPlus"
    fi
    if [[ "$UseOBJCOPYBinutils" == "y" ]];then
        MorePlusPlus="OBJCOPY=$for64-objcopy $MorePlusPlus"
    else
        MorePlusPlus="OBJCOPY=${PrefixDir}llvm-objcopy $MorePlusPlus"
    fi
    echo "MorePlusPlus : $MorePlusPlus"
    make -j$(nproc) O=out ARCH=arm64 $DEVICE_DEFCONFIG
    make -j$(nproc) ARCH=arm64 O=out \
               PATH=${ClangPath}/bin:${GCCaPath}/bin:${GCCbPath}/bin:/usr/bin:${PATH} \
                LD_LIBRARY_PATH="${ClangPath}/lib64:${GCCaPath}/lib:${GCCbPath}/lib:${LD_LIBRARY_PATH}" \
                CC=clang \
                CROSS_COMPILE=$for64- \
                CROSS_COMPILE_ARM32=$for32- \
                CLANG_TRIPLE=aarch64-linux-gnu- \
                AR=${PrefixDir}llvm-ar \
                NM=${PrefixDir}llvm-nm \
                STRIP=${PrefixDir}llvm-strip \
                READELF=${PrefixDir}llvm-readelf \
                HOSTAR=${PrefixDir}llvm-ar ${MorePlusPlus} LLVM=1 2>&1 | tee error.log

   if ! [ -a "$IMAGE" ]; then
	finerr
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
function finerr() {
    cd out
    LOG=$(echo error.log)
    tg_post_msg "Terjadi Error Dalam Proses Compile❌"
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
    zip -r9 [$VERSION][$TYPE]$DEVICE_CODENAME[$CODENAME][$KERNELNAME]-$DATE.zip * -x .git README.md *placeholder
    cd ..
}
CloneKernel
CloneClang
CloneGcc
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
