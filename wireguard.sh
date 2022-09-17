#!/usr/bin/env bash
# declare constants
DIR=$(pwd)
repo="https://github.com/WireGuard/wireguard-linux-compat"
repodir="wireguard-linux-compat"

# initialize
rm -rf ${repodir}

# questionaries
echo -ne "\033[1;36m Provide latest version of wireguard: \033[0m"
read -r ver
echo -ne "\033[1;36m Provide path to kernel source: \033[0m"
read -r path
if [ -d "${path}/net/wireguard" ]; then
	rm -rf ${path}/net/wireguard
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
mkdir "${path}"/net/wireguard

# copy from cloned repo
cp -r "${repodir}"/src/* "${path}"/net/wireguard/

# git add and commit
cd "${path}" || exit 1
git add net/wireguard/*
git commit -s -m "wireguard: Update to ${ver}
  from ${repo}/tree/master/src"

# finalize
cd "${DIR}" || exit 1
echo -e "\n\033[1;36m Done! Merged latest wireguard ${ver} \033[0m"
rm -rf ${repodir}
