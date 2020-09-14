#!/bin/bash

# Set UID and GID

PUID=${PUID:-1001}
PGID=${PGID:-1001}

# Change UID and GID for user
groupmod -o -g "$PGID" abc &> /dev/null
usermod -o -u "$PUID" abc &> /dev/null
chown abc:abc /home/abc

# Add repo to pacman.conf
cat <<EOF >> /etc/pacman.conf
[${REPO_NAME}]
SigLevel = Optional TrustAll
Server = file:///repo
EOF

# Create repo and chown it
if [ -d /repo ];then #Check if repo already exists
	chown abc:abc /repo
	if [ -f /repo/${REPO_NAME}.db.tar.xz ];then
		echo -e "\e[33mRepo already exists!\e[39m"
	else # Start the repo
		runuser -l abc -c "repo-add /repo/${REPO_NAME}.db.tar.xz &> /dev/null"
		echo -e "\e[32mSucessfully created the repo: ${REPO_NAME}\e[39m"
	fi
else
	mkdir /repo
	chown abc:abc /repo
	runuser -l abc -c "repo-add /repo/${REPO_NAME}.db.tar.xz &> /dev/null"
	echo -e "\e[32mSucessfully created the repo: ${REPO_NAME}\e[39m"
fi

# Update the Cache
pacman -Syu &> /dev/null

# Add packages from the envs
for package in $(echo "$PACKAGES" | tr "," " "); do
	if [ -f /repo/${package}* ];then
		echo -e "\e[33m${package} is already on the repo!\e[39m"
	else
		echo -e "\e[34mAdding ${package} to the repo!\e[39m"
		BUILD_START=$(date +%s)
		runuser -l abc -c "aur sync --no-view --noconfirm \
			-d ${REPO_NAME} \
			-r /repo \
			${package} &> /dev/null"
		if [ $? == '1' ];then
			echo -e "\e[31mSomething went wrong during the build of ${package}!\e[39m"
		else
			BUILD_END=$(date +%s)
			DIFF=$(($BUILD_END - $BUILD_START))
			echo -e "\e[32mSucessfully built ${package} in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.\e[39m"
		fi
	fi
done

# Setup Time
ln -sf /usr/share/zoneinfo/$TZ /etc/localtime

# Add Cronjob
echo "${CRON} /bin/bash /update.sh" > /var/spool/cron/abc

# Execute Cronjob
/usr/sbin/crond -x ext &> /dev/null
