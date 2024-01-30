#!/usr/bin/env bash
# declare constants
DIR=$(pwd)
repo="https://github.com/tiann/KernelSU"
repodir="KernelSU"

# initialize
rm -rf ${repodir}

# questionaries
echo -ne "\033[1;36m Provide path to kernel source: \033[0m"
read -r path
if [ -d "${path}/drivers/kernelsu" ]; then
	rm -rf ${path}/drivers/kernelsu
	cd ${path} || exit 1
#	git add net/wireguard
#	git commit -s -m "net: removed wireguard from net"
        cd "${DIR}"
fi

# clone
git clone ${repo} ${repodir}
cd ${repodir}
git describe --tags $(git rev-list --tags --max-count=1) | tee kssu.txt
git rev-list --count $(git describe --tags $(git rev-list --tags --max-count=1)) | tee ksuversion.txt
cd $DIR
ksugitversion=$(cat ${repodir}/ksuversion.txt)
ksuversion=$(expr 10000 + $ksugitversion + 200)
ksutag=$(cat ${repodir}/kssu.txt)
#wget https://git.zx2c4.com/wireguard-linux-compat/snapshot/wireguard-linux-compat-"${ver}".zip
#unzip wireguard-linux-compat-"${ver}".zip -d wireguard

# make deleted dir
mkdir "${path}"/drivers/kernelsu

# copy from cloned repo
cp -r "${repodir}"/kernel/* "${path}"/drivers/kernelsu

# git add and commit
cd "${path}" || exit 1
git add drivers/kernelsu/*
git commit -s -m "kernelsu: sync ${ksutag} tag with repo
  from ${repo}/tree/main/kernel
  using script from https://github.com/realme-sm7125/myscripts/blob/main/kernelsu.sh
 Referenced from https://kernelsu.org/guide/how-to-integrate-for-non-gki.html#integrate-with-kprobe
 and edited a bit to be compatible for CI builds"
echo ""

# add kernelsu nongki amd non kprobe related commit
echo -ne "Do you want to reeapply patch in kernelsu [y/n]: "
read -r kksu
if [[ "${kksu}" == "y" ]]; then
    echo "Applying" && echo ""
    wget https://raw.githubusercontent.com/realme-sm7125/myscripts/main/patches/ksu-reapply-kprobes.patch
    git apply ksu-reapply-kprobes.patch
    rm -rf ksu-reapply-kprobes.patch
    git add .
    git commit -s --author="onettboots <blackcocopet@gmail.com>" -m "[REAPPLY] kernelsu: we're non GKI and non KPROBES build
    This is an automated commit using script from
    https://github.com/realme-sm7125/myscripts/blob/main/kernelsu.sh"
    echo "Done"
elif [[ "${kksu}" == "n" ]]; then
    echo "Skipping" && echo ""
fi
echo ""

# update kernelsu version
echo "Updating KSU version"
echo ""
sed -i "s/^#define KERNEL_SU_VERSION.*/#define KERNEL_SU_VERSION ($ksuversion)/g" drivers/kernelsu/ksu.h
sed -i 's:ifeq ($(shell test -e $(srctree)/$(src)/../.git; echo $$?),0):ifeq ($(shell test -e drivers/kernelsu; echo $$?),0):g' drivers/kernelsu/Makefile
sed -i "s/^KSU_GIT_VERSION.*/KSU_GIT_VERSION := ($ksugitversion)/g" drivers/kernelsu/Makefile
echo "Updated"
git add drivers/kernelsu/*
git commit -s -m "kernelsu: hardcode update kernelsu version to $ksuversion
  update ksu version and also suppress compilation warning
  using script from https://github.com/realme-sm7125/myscripts/blob/main/kernelsu.sh"
echo ""

# finalize
cd "${DIR}" || exit 1
echo -e "\n\033[1;36m Done! Synced with latest kernelsu \033[0m"
rm -rf ${repodir}
