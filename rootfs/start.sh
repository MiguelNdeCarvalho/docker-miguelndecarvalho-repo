#!/bin/bash

# Set UID and GID

PUID=${PUID:-1001}
PGID=${PGID:-1001}

# Change UID and GID for user
groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc

# Create repo and chown it
mkdir /repo
chown abc:abc /home/abc
chown abc:abc /repo

# Add repo to pacman.conf
cat <<EOF >> /etc/pacman.conf
[${REPO_NAME}]
SigLevel = Optional TrustAll
Server = file:///repo
EOF

# Start the repo
runuser -l abc -c "repo-add /repo/${REPO_NAME}.db.tar.xz"

# Update the Cache
pacman -Syyu

# Add packages from the envs
for package in $(echo "$PACKAGES" | tr "," " "); do
	echo "Adding ${package} to the repo"
	runuser -l abc -c 'cd / && aur sync --no-view --noconfirm \
		-d ${REPO_NAME} \
		-r repo \
		${package}'
done
