#!/usr/bin/env bash
DIR=$(pwd)
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
wget https://git.zx2c4.com/wireguard-linux-compat/snapshot/wireguard-linux-compat-"${ver}".zip
unzip wireguard-linux-compat-"${ver}".zip -d wireguard
mkdir "${path}"/net/wireguard
cp -r wireguard/*/src/* "${path}"/net/wireguard/
cd "${path}" || exit 1
git add net/wireguard/*
git commit -s -m "wireguard: Update to ${ver}"
cd "${DIR}" || exit 1
echo -e "\n\033[1;36m Done! Merged latest wireguard ${ver} \033[0m"
