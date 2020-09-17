#!/bin/bash

set -e

# Install needed packages

pacman -Syu --noconfirm --needed \
	base-devel \
	git \
	devtools \
	cronie

# Create ABC User and add it to Sudoers
mkdir /home/abc
useradd -d /home/abc abc
chown abc /home/abc
echo "abc ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install Aurutils from AUR
runuser -l abc -c 'git clone --depth 1 https://aur.archlinux.org/aurutils.git /home/abc/aurutils/'
runuser -l abc -c 'pacman-key --export DBE7D3DD8C81D58D0A13D0E76BC26A17B9B7018A | gpg --import'
runuser -l abc -c 'cd /home/abc/aurutils/ && makepkg --noconfirm -sci && rm -rf /home/abc/aurutils/'
echo "AurUtils installed sucessfully"
