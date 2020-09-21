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
	if ! grep -q "$REPO_NAME" "/etc/pacman.conf"; then
		echo -e "[$REPO_NAME]\nSigLevel = Optional TrustAll\nServer = file:///repo" >> /etc/pacman.conf	
	fi

	# Create repo and chown it
	if [ -d /repo ];then #Check if repo already exists
		chown abc:abc /repo
		if [ ! -f /repo/"${REPO_NAME}".db.tar.xz ];then
			runuser -l abc -c "repo-add /repo/${REPO_NAME}.db.tar.xz &> /dev/null"
			echo -e "\e[32mSucessfully created the repo: ${REPO_NAME}\e[39m"
		fi
	else
		mkdir /repo
		chown abc:abc /repo
		runuser -l abc -c "repo-add /repo/${REPO_NAME}.db.tar.xz &> /dev/null"
		echo -e "\e[32mSucessfully created the repo: ${REPO_NAME}\e[39m"
	fi

	# Update the System
	pacman -Syu --noconfirm &> /dev/null

	# Setup Time
	ln -sf /usr/share/zoneinfo/"$TZ" /etc/localtime

	# Add .env file
	if [ ! -f /home/abc/.env ]; then
    	echo -e "export REPO_NAME=$REPO_NAME\nexport TG_TOKEN=$TG_TOKEN\nexport TG_ID=$TG_ID" > /home/abc/.env
		chown abc:abc /home/abc/.env
	fi

	# Create alias
	if [ ! -f /usr/bin/update ];then
		echo -e '#!/bin/bash\nrunuser -l abc -c "/update.sh"' > /usr/bin/update
		chmod +x /usr/bin/update
	fi
	if [ ! -f /usr/bin/rm ];then
		echo -e '#!/bin/bash\nrunuser -l abc -c "/remove.sh $1"' > /usr/bin/rm
		chmod +x /usr/bin/rm
	fi

	# Add Cronjob
	echo "${CRON} source /home/abc/.env && /update.sh >> /home/abc/cron_repo 2>&1" > /var/spool/cron/abc
}

send_notification ()
{
	curl -s -X POST https://api.telegram.org/bot"$TG_TOKEN"/sendMessage \
	-d parse_mode=HTML  \
	-d chat_id="$TG_ID" \
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

add_keys ()
{
	for key in $(echo "$KEYS" | tr "," " "); do
		gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $key &> /dev/null
	done
}

add_packages ()
{
	# Add packages from the envs
	for package in $(echo "$PACKAGES" | tr "," " "); do
		if package_exists "$package";then
			echo -e "\e[33m${package} is already on the repo!\e[39m"
		else
			build "$package"
		fi
	done
}

main ()
{
	setup
	add_packages
	add_keys
	
	# Execute Cronjob
	echo -e "Cron started."
	/usr/sbin/crond -x ext &> /dev/null
}

main
