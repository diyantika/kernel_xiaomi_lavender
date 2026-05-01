#!/bin/sh

# Many parts of this script were taken from @REIGNZ, @idkwhoiam322 and @raphielscape . Huge thanks to them.
#Cleaning
rm -rf out
make clean
make mrproper
# Some general variables
PHONE="dipper"
ARCH="arm64"
SUBARCH="arm64"
DEFCONFIG=lvn_defconfig
#DEFCONFIG=beryllium_defconfig
COMPILER=clang
LINKER=""
COMPILERDIR="$(pwd)/clang"

if [ ! -d "$COMPILERDIR" ]; then
mkdir clang
cd clang
 wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/42d2c090c14c9c7f4dfd365ae551e2b959dc775c/clang-r584948b.tar.gz && tar -xf * && rm -rf *.gz
cd ..
    fi

# Outputs
mkdir -p zone_dipper
mkdir -p out/outputs
mkdir -p out/outputs/${PHONE}
mkdir -p out/outputs/${PHONE}/NSE

# Export shits
export KBUILD_BUILD_USER=Zone
export KBUILD_BUILD_HOST=D543

# Speed up build process
MAKE="./makeparallel"

# Basic build function
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

Build () {
PATH="${COMPILERDIR}/bin:${PATH}" \
make -j$(nproc --all) O=out \
ARCH=${ARCH} \
LLVM=1 LLVM_IAS=1 \
CC=${COMPILER} \
CROSS_COMPILE=${COMPILERDIR}/bin/aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=${COMPILERDIR}/bin/arm-linux-gnueabi- \
LD=ld.lld \
AR=llvm-ar \
NM=llvm-nm \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
STRIP=llvm-strip \
LD_LIBRARY_PATH=${COMPILERDIR}/lib
}

# Make defconfig

make O=out ARCH=${ARCH} ${DEFCONFIG}
if [ $? -ne 0 ]
then
    echo "Build failed"
else
    echo "Made ${DEFCONFIG}"
fi

# Build starts here
    #NSE
    Build
    if [ $? -ne 0 ]
    then
        echo "Build failed"
        rm -rf out/outputs/${PHONE}/NSE/*
    else
        echo "Build succesful"
        cp out/arch/arm64/boot/Image.gz-dtb out/outputs/${PHONE}/NSE/Image.gz-dtb
    fi

#Anykernel 
if [ ! -d "AnyKernel3" ]; then
            git clone -q https://github.com/diyantika/AnyKernel3.git -b Dipper-SE AnyKernel3
        fi
        
Zipping () {
       ZIPNAME="${PHONE}.zip"
       cd AnyKernel3
        git checkout Dipper-SE &> /dev/null
        zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
        cd ..
        #Pindah Zip
        mv "$ZIPNAME" zone_dipper/
       }

#NSE
cp out/outputs/${PHONE}/NSE/Image.gz-dtb AnyKernel3/
Zipping "NSE"

rm -rf AnyKernel3/

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
