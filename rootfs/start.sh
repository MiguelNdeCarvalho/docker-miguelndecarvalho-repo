#!/bin/bash

setup ()
{
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
		if [ -f /repo/"${REPO_NAME}".db.tar.xz ];then
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

	# Setup Time
	ln -sf /usr/share/zoneinfo/"$TZ" /etc/localtime

	# Add Cronjob
	echo "${CRON} /bin/bash /update.sh" > /var/spool/cron/abc
}

send_notification ()
{
	curl -s -X POST https://api.telegram.org/bot$TG_TOKEN/sendMessage \
	-d parse_mode=HTML  \
	-d chat_id=$TG_ID \
	-d text="<b>$REPO_NAME</b>%0A$1"
}

build ()
{
	echo -e "\e[34mAdding ${1} to the repo!\e[39m"
	BUILD_START=$(date +%s)
	runuser -l abc -c "aur sync --no-view --noconfirm \
		-d ${REPO_NAME} \
		-r /repo \
		${1} &> /dev/null"
	if ! runuser -l abc -c "aur sync --no-view --noconfirm -d ${REPO_NAME} -r /repo ${1} &> /dev/null";then
		echo -e "\e[31mSomething went wrong during the build of ${1}!\e[39m"
		send_notification "Build failed for $1"
	else
		BUILD_END=$(date +%s)
		DIFF=$((BUILD_END - BUILD_START))
		echo -e "\e[32mSucessfully built ${1} in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds.\e[39m"
	fi
}

package_exists ()
{
	for f in /repo/"$1"*; do
		if [ -e "$f" ];then 
			return 0
		else
			return 1
		fi
		break
	done
}

add_packages ()
{
	# Add packages from the envs
	for package in $(echo "$PACKAGES" | tr "," " "); do
		if package_exists "$package";then
			echo -e "\e[33m${package} is already on the repo!\e[39m"
		elif [ "$package" == 'spotify' ];then
			echo -e "\e[33m${package} package detected, adding GPG key needed for the build!\e[39m"
			runuser -l abc -c "curl -sS https://download.spotify.com/debian/pubkey.gpg | gpg --import -" &> /dev/null
			build "$package"
		else
			build "$package"
		fi
	done
}

main ()
{
	setup
	add_packages
	
	# Execute Cronjob
	/usr/sbin/crond -x ext &> /dev/null
}

main