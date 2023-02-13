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
if [ -d "${path}/net/wireguard" ]; then
	rm -rf ${path}/drivers/kernelsu
	cd ${path} || exit 1
#	git add net/wireguard
#	git commit -s -m "net: removed wireguard from net"
        cd "${DIR}"
fi

# clone
git clone ${repo} ${repodir}
#wget https://git.zx2c4.com/wireguard-linux-compat/snapshot/wireguard-linux-compat-"${ver}".zip
#unzip wireguard-linux-compat-"${ver}".zip -d wireguard

# make deleted dir
mkdir "${path}"/drivers/kernelsu

# copy from cloned repo
cp -r "${repodir}"/kernel/* "${path}"/drivers/kernelsu

# git add and commit
cd "${path}" || exit 1
git add drivers/kernelsu/*
git commit -s -m "kernelsu: sync with repo
  from ${repo}/tree/main/kernel
 Referenced from https://kernelsu.org/guide/how-to-integrate-for-non-gki.html#integrate-with-kprobe
 and edited a bit to be compatible for CI builds"

# finalize
cd "${DIR}" || exit 1
echo -e "\n\033[1;36m Done! Synced with latest kernelsu \033[0m"
rm -rf ${repodir}
