#!/usr/bin/with-contenv bash
# shellcheck shell=bash

print_time ()
{
	echo -e "\e[34m$(date "+%d/%m/%Y %H:%M:%S") - $1\e[39m"	
}

send_notification ()
{
	curl -s -X POST https://api.telegram.org/bot"$TG_TOKEN"/sendMessage \
	-d parse_mode=HTML  \
	-d chat_id="$TG_ID" \
	-d text="<b>$REPO_NAME</b>%0A$1" &> /dev/null
}

update_system ()
{
	print_time "Performing a system update"
	sudo pacman -Syu --noconfirm &> /dev/null
}

build ()
{
	BUILD_START=$(date +%s)
	aur sync --no-view --noconfirm \
		-d "${REPO_NAME}" \
		-r /repo \
		-R -u &> /tmp/update
	EXIT_CODE="$?"
	if [ "$EXIT_CODE" == '0' ];then
		BUILD_END=$(date +%s)
		DIFF=$((BUILD_END - BUILD_START))
		PACKAGES_UPDATED=$(grep "==> Adding package" /tmp/update | grep -Eo "'.*'" | sed "s/'//g" | sed "s/.pkg.tar.zst//g" | sed "s/-[0-9].*//g")
		send_notification "Repo has been updated%0APackages Updated:$PACKAGES_UPDATED%0AIt took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds."
	elif [ "$EXIT_CODE" == '123' ];then
		return 123 
	else
		LOGS_URL=$(/app/privatebin < /tmp/update)
		send_notification "Something went wrong during the update of the repo!%0ALogs:$LOGS_URL"
	fi
	rm /tmp/update
}

main ()
{
	HOME="/config"
	print_time "Starting repo update process"
	update_system
	build
	print_time "Finished repo update process"
}

main
