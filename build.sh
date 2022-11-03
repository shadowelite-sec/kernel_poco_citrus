#!/bin/bash

wd=$(pwd)
out=$wd"/out"
KERNEL_DIR=$wd
ANYKERNEL_DIR=$wd"/../AnyKernel3"
IMG=$out"/arch/arm64/boot/Image"
DATE="`date +%d_%m_%Y_%a_%I-%M-%S-%P`" 
grp_chat_id=""
chat_id="872750064"
token=$(echo "MTI1NTcyNDg1MjpBQUVoTy16NjFyWmpfSGJNdENESnJmSFUyOUVvTVJub3dWZwo=" | base64 -d)
TC=aarch64-linux-gnu-gcc
function set_param_clang()
{
    # Export ARCH <arm, arm64, x86, x86_64>
    export ARCH=arm64
    #Export SUBARCH <arm, arm64, x86, x86_64>
    export SUBARCH=arm64



    # Compiler
    GCC32=$HOME/toolchains/clang2/bin/arm-linux-gnueabi-
    GCC64=$HOME/toolchains/clang2/bin/aarch64-linux-gnu-
    GCC64_TYPE=aarch64-linux-gnu-

    # Compiler String
    TC=$HOME/toolchains/clang2/bin/clang
    CLANG_DIR=$HOME/toolchains/clang2
    COMPILER_STRING="$(${TC} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_w  eb_page_preview=true" -d "parse_mode=html&text=<b>Making menuconfig ... .</b>"  /g' | sed 's/ *$//')"
    export KBUILD_COMPILER_STRING="${COMPILER_STRING}"
}

function set_param_gcc()
{
    #Export compiler dir.
    export CROSS_COMPILE="$HOME/toolchains/gcc64/bin/aarch64-linux-gnu-"
    export CROSS_COMPILE_ARM32="$HOME/toolchains/gcc32/bin/arm-linux-gnueabi-"

    # Export ARCH <arm, arm64, x86, x86_64>
    export ARCH=arm64
    #Export SUBARCH <arm, arm64, x86, x86_64>
    export SUBARCH=arm64

    # Kbuild host and user
    export KBUILD_BUILD_USER="S133PY"
    export KBUILD_BUILD_HOST="Kali"
    export KBUILD_JOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"

    TC=$HOME/toolchains/gcc64/bin/aarch64-linux-gnu-gcc
    COMPILER_STRING="$(${wd}"/gcc64/bin/aarch64-linux-gnu-gcc" --version | head -n 1)"
    export KBUILD_COMPILER_STRING="${COMPILER_STRING}"
}

function checkout_source()
{
    # Checkout to kernel source
    cd "${KERNEL_DIR}"
}


function build_clang()
{
    #checkout_source
    set_param_clang
    # Push build message to telegram
    tg_inform

    #make clean mrproper 
    #make O="$out" clean mrproper
    rm -rf out

    make O="$out" vendor/citrus-nethunter-perf_defconfig #citrus-nethunter-perf_defconfig #citrus-stock-perf_defconfig
    tg_menu
    make O="$out" menuconfig

    tg_change

    tg_started

    clear
    #start
    toilet -f future --filter border:metal BUILD START | lolcat

    BUILD_START=$(date +"%s")

    make -j6 O=$out CC="${TC}" LLVM_AR="${CLANG_DIR}/bin/llvm-ar" LLVM_NM="${CLANG_DIR}/bin/llvm-nm" OBJCOPY="${CLANG_DIR}/bin/llvm-objcopy" OBJDUMP="${CLANG_DIR}/bin/llvm-objdump" STRIP="${CLANG_DIR}/bin/llvm-strip" CROSS_COMPILE="${GCC64}" CROSS_COMPILE_ARM32="${GCC32}" CLANG_TRIPLE="${GCC64_TYPE}" 2>&1| tee $out/build.log
    make -j6 O=$out CC="${TC}" LLVM_AR="${CLANG_DIR}/bin/llvm-ar" LLVM_NM="${CLANG_DIR}/bin/llvm-nm" OBJCOPY="${CLANG_DIR}/bin/llvm-objcopy" OBJDUMP="${CLANG_DIR}/bin/llvm-objdump" STRIP="${CLANG_DIR}/bin/llvm-strip" CROSS_COMPILE="${GCC64}" CROSS_COMPILE_ARM32="${GCC32}" CLANG_TRIPLE="${GCC64_TYPE}" modules_install INSTALL_MOD_PATH=modules_out 
    
    BUILD_END=$(date +"%s")
    DIFF=$(($BUILD_END - $BUILD_START))

    if [ -f "${IMG}" ]; then
        echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)."
        flash_zip
    else
        tg_push_error
    echo -e "Build failed, please fix the errors first bish!"
  fi
#end 
toilet -f future --filter border:metal BUILD END | lolcat

echo "==========================================================="

echo "build log is here : $(curl -s -F "file=@$out/build.log" 0x0.st) "

echo "==========================================================="

}

function build_gcc()
{
    #clone_gcc
    #checkout_source
    set_param_gcc
    # Push build message to telegram
    tg_inform

    make O="${out}" clean
    make O="${out}" mrproper
    rm -rf "${out}"
    make O="${out}" citrus-stock-perf_defconfig

    BUILD_START=$(date +"%s")
    make O="${out}" -j6 2>&1| tee "${out}"/build.log
    
    BUILD_END=$(date +"%s")
    DIFF=$(($BUILD_END - $BUILD_START))

    if [ -f "${IMG}" ]; then
        echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)."
        flash_zip
    else
        tg_push_error
    echo -e "Build failed, please fix the errors first bish!"
  fi
}

function flash_zip()
{
    echo -e "Now making a flashable zip of kernel with AnyKernel3"

    tg_ziping

    export ZIPNAME=ShadowElite-Nethunter-POCO-M3-$DATE.zip

    # Checkout anykernel3 dir
    cd "$ANYKERNEL_DIR"

    # Cleanup and copy Image.gz-dtb to dir.
    rm -f ShadowElite-*.zip
    rm -f Image

    #copy modules
    #cp -r $out/modules_out/* $ANYKERNEL_DIR/modules/

    # Copy Image.gz-dtb to dir.
    cp $out/arch/arm64/boot/Image ${ANYKERNEL_DIR}/
    rm $ANYKERNEL_DIR/modules/lib/modules/*/source
    rm $ANYKERNEL_DIR/modules/lib/modules/*/build

    # Build a flashable zip
    zip -r9 $ZIPNAME * -x .git README.md
    MD5=$(md5sum ShadowElite-*.zip | cut -d' ' -f1)
    tg_sending
    tg_push_log
    tg_push
   # rm -rf $out
}


function tg() {

curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=Markdown&text=$?"

}



function tg_menu()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>Making menuconfig ... .</b>"
}

function tg_started()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b> 🔨 Build Started .....</b>"
}

function tg_inform()
{
        curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>⚒️ New CI build has been triggered"'!'" ⚒️</b>%0A%0A<b>Linux Version • </b><code>$(make kernelversion)</code>%0A<b>Compiler • </b><code>$(${TC} --version --version | head -n 1)</code>%0A<b>At • </b><code>$(TZ=Asia/Kolkata date)</code>%0A"  
}

function tg_push()
{
    ZIP="${ANYKERNEL_DIR}"/$(echo ShadowElite-*.zip)
    curl -F document=@"${ZIP}" "https://api.telegram.org/bot${token}/sendDocument" \
      -F chat_id="$chat_id" \
      -F "disable_web_page_preview=true" \
      -F "parse_mode=html" \
            -F caption="🛠️ Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | <b>MD5 checksum</b> • <code>${MD5}</code>"
}

function tg_push_error()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>❌ Build failed after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s).</b>"
}

function tg_push_log()
{
    LOG=$out/build.log
    LOG_LINK=$(curl -s -F "file=@$LOG" 0x0.st)
  curl -F document=@"${LOG}" "https://api.telegram.org/bot$token/sendDocument" \
      -F chat_id="$chat_id" \
      -F "disable_web_page_preview=true" \
      -F "parse_mode=html" \
            -F caption="🛠️ Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). @shadowelite"
}

function tg_ziping()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b> Building flashable zip ....</b>"
}

function tg_sending()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>Sending flashable zip wait ...</b>"
}
#tg
build_clang
