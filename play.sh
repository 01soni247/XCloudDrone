# !/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Main
MainPath=$(pwd)
MainClangPath=${MainPath}/clang
MainClangZipPath=${MainPath}/clang-zip
ClangPath=${MainClangZipPath}
GCCaPath=${MainPath}/GCC64
GCCbPath=${MainPath}/GCC32
MainZipGCCaPath=${MainPath}/GCC64-zip
MainZipGCCbPath=${MainPath}/GCC32-zip
GCCcPath=${MainPath}/GCC64z
GCCdPath=${MainPath}/GCC32z
CLANG_ROOTDIR=$(pwd)/clang
MainZipGCCcPath=${MainPath}/GCC64z-zip
MainZipGCCdPath=${MainPath}/GCC32z-zip

CloneFourteenGugelClang(){
    ClangPath=${MainClangZipPath}
    [[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
    mkdir $ClangPath
        wget -q  https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r437112b.tar.gz -O "clang-r437112b.tar.gz"
    tar -xf clang-r437112b.tar.gz -C $ClangPath
    rm -rf clang-r437112b.tar.gz
}

CloneAtomClang(){
    git clone --depth=1 https://gitlab.com/ElectroPerf/atom-x-clang $ClangPath
}

CloneGKClang(){
    git clone --depth=1 https://github.com/GengKapak/GengKapak-clang -b 12 clang
}

ClProton(){
    git clone --depth=1 https://github.com/HANA-CI-Build-Project/proton-clang -b proton-clang-11 clang
}

CloneCompiledGccTwelve(){
        git clone https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 12 $GCCaPath --depth=1
        git clone https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 12 $GCCbPath --depth=1
}

START=$(date +"%s")

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"
}
CloneFourteenGugelClang
CloneCompiledGccTwelve
# CloneSeaClang
# CloneGKClang
# ClProton
END=$(date +"%s")
DIFF=$(($END - $START))
