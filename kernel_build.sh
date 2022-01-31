
#!/usr/bin/env bash

#
# Script For Building Android arm64 Kernel
#

# Device Name and Codename of the device
MODEL="RMX2170"

DEVICE="Realme 7 Pro | Realme 6 Pro"

# Kernel name
KERNELNAME="Mello-Oof-Ultra-Pro-...-Plus"

# Your Name
USER="Mayur"

# The defconfig which needs to be used
DEFCONFIG=atoll_defconfig

# Kernel Directory
KERNEL_DIR=$(pwd)

# The version code of the Kernel
VERSION=v0.69+7

# Path of final Image 
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb

#DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img

# Modules path (total 11)
M1=$(pwd)/out/drivers/media/platform/msm/dvb/demux/mpq-dmx-hw-plugin.ko
M2=$(pwd)/out/drivers/char/rdbg.ko
M3=$(pwd)/out/drivers/media/usb/gspca/gspca_main.ko
M4=$(pwd)/out/drivers/video/backlight/lcd.ko
M5=$(pwd)/out/drivers/media/rc/msm-geni-ir.ko
M6=$(pwd)/out/drivers/media/platform/msm/dvb/adapter/mpq-adapter.ko
M7=$(pwd)/out/drivers/soc/qcom/llcc_perfmon.ko
M8=$(pwd)/out/drivers/mmc/core/mmc_test.ko
M9=$(pwd)/out/net/bridge/br_netfilter.ko
M10=$(pwd)/out/drivers/net/wireless/ath/wil6210/wil6210.ko
M11=$(pwd)/out/drivers/platform/msm/msm_11ad/msm_11ad_proxy.ko

# Compiler which needs to be used (Clang or gcc)
COMPILER=clang

# Verbose build
# 0 is Quiet | 1 is verbose | 2 gives reason for rebuilding targets
VERBOSE=0

# For Drone CI
                export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
		export KBUILD_BUILD_HOST=$DRONE_SYSTEM_HOST
		export CI_BRANCH=$CIRCLE_BRANCH
		export BASEDIR=$DRONE_REPO_NAME # overriding
		export SERVER_URL="${DRONE_SYSTEM_PROTO}://${DRONE_SYSTEM_HOSTNAME}/ayash92/${BASEDIR}/${KBUILD_BUILD_VERSION}"
                export PROCS=$(nproc --all)

# Set Indian timezone
date #show me first
currentzone=$(date +"%Z")
oldzone=$currentzone
echo "Current timezone is $currentzone" && echo ""
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Calcutta /etc/localtime
date #show me first
currentzone=$(date +"%Z")
echo "Current timezone is $currentzone" && echo ""
echo "Timezone changed from $oldzone to $currentzone" && echo ""

# Set Date 
DATE=$(TZ=Asia/Kolkata date +"%Y%m%d-%T")
START=$(date +"%s")
DATE_POSTFIX=$(date +"%Y%m%d-%H%M%S")
DATEDAY=$(date +"%Y%m%d")
DATETIME=$(date +"%H%M%S")

# Set a commit head
COMMIT_HEAD=$(git log --oneline -1)

#Check Kernel Version
KERVER=$(make kernelversion)

clone() {
	echo " Cloning Dependencies "
	if [ $COMPILER = "gcc" ]
	then
		echo "|| Cloning GCC ||"
		git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git gcc64
                git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git gcc32
	elif [ $COMPILER = "clang" ]
	then
	        echo  "|| Cloning Azure Clang ||"
		git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang clang
	fi

         echo "|| Cloning Anykernel ||"
	git clone https://github.com/marshmello61/AnyKernel3
}

# Export
export ARCH=arm64
export SUBARCH=arm64
export LOCALVERSION="-${VERSION}"
export KBUILD_BUILD_HOST=mayur
export KBUILD_BUILD_USER="ultra"

function XD() {
if [ $COMPILER = "clang" ]
	then
        export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
		PATH="${PWD}/clang/bin:$PATH"
	elif [ $COMPILER = "gcc" ]
	then
		export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/gcc64/bin/aarch64-elf-gcc --version | head -n 1)
		PATH=${KERNEL_DIR}/gcc64/bin/:$KERNEL_DIR/gcc32/bin/:/usr/bin:$PATH
	fi
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>$KBUILD_BUILD_VERSION CI Build Triggered by ${USER}</b>%0A<b>CI build link: </b>$CIRCLE_BUILD_URL%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
}
# Push kernel to channel
function push() {
    cd AnyKernel3
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b>"
}
# Fin Error
function finerr() {
    LOG=error.log
   curl -F document=@$LOG "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {

    if [ $COMPILER = "clang" ]
	then
		make O=out ARCH=arm64 ${DEFCONFIG}
		make -j$(nproc --all) O=out \
				ARCH=arm64 \
				CC=clang \
				AR=llvm-ar \
				NM=llvm-nm \
				OBJCOPY=llvm-objcopy \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip \
                                V=$VERBOSE \
				CROSS_COMPILE=aarch64-linux-gnu- \
          CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1 | tee error.log

	elif [ $COMPILER = "gcc" ]
	then
	        make O=out ARCH=arm64 ${DEFCONFIG}
	        make -j$(nproc --all) O=out \
	    	                ARCH=arm64 \
                                CROSS_COMPILE_ARM32=arm-eabi- \
                                CROSS_COMPILE=aarch64-elf- \
			        AR=aarch64-elf-ar \
			        OBJDUMP=aarch64-elf-objdump \
			        STRIP=aarch64-elf-strip \
                                V=$VERBOSE 2>&1 | tee error.log
	fi

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    echo "Copying Kernel image" && echo ""
    cp $IMAGE AnyKernel3
    [ -e "AnyKernel3/Image.gz-dtb" ] && echo "Image copied" || echo "Image didn't copied"
#    cp $DTBO AnyKernel3
    echo "Copying modules" && echo ""
    mkdir -p AnyKernel3/modules/vendor/lib/modules
    [ -e "$M1" ] && cp $M1 AnyKernel3/modules/vendor/lib/modules && echo "Module 1 copied" || echo "Module 1 not found"
    [ -e "$M2" ] && cp $M2 AnyKernel3/modules/vendor/lib/modules && echo "Module 2 copied" || echo "Module 2 not found"
    [ -e "$M3" ] && cp $M3 AnyKernel3/modules/vendor/lib/modules && echo "Module 3 copied" || echo "Module 3 not found"
    [ -e "$M4" ] && cp $M4 AnyKernel3/modules/vendor/lib/modules && echo "Module 4 copied" || echo "Module 4 not found"
    [ -e "$M5" ] && cp $M5 AnyKernel3/modules/vendor/lib/modules && echo "Module 5 copied" || echo "Module 5 not found"
    [ -e "$M6" ] && cp $M6 AnyKernel3/modules/vendor/lib/modules && echo "Module 6 copied" || echo "Module 6 not found"
    [ -e "$M7" ] && cp $M7 AnyKernel3/modules/vendor/lib/modules && echo "Module 7 copied" || echo "Module 7 not found"
    [ -e "$M8" ] && cp $M8 AnyKernel3/modules/vendor/lib/modules && echo "Module 8 copied" || echo "Module 8 not found"
    [ -e "$M9" ] && cp $M9 AnyKernel3/modules/vendor/lib/modules && echo "Module 9 copied" || echo "Module 9 not found"
    [ -e "$M10" ] && cp $M10 AnyKernel3/modules/vendor/lib/modules && echo "Module 10 copied" || echo "Module 10 not found"
    [ -e "$M11" ] && cp $M11 AnyKernel3/modules/vendor/lib/modules && echo "Module 11 copied" || echo "Module 11 not found"

}
# Zipping
function zipping() {
    cd AnyKernel3 || exit 1
    zip -r9 ${KERNELNAME}-${VERSION}_${MODEL}-${DATE_POSTFIX}.zip *
    cd ..
}
clone
XD
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
