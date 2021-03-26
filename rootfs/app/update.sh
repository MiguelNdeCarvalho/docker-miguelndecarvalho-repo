#!/usr/bin/with-contenv bash
# shellcheck shell=bash

REPO_PATH="/config/repo"

print_time ()
{
	echo -e "\e[34m$(date "+%d/%m/%Y %H:%M:%S") - $1\e[39m"	
}

success_notification ()
{
	response='
	{
	  "embeds":[
	    {
	      "description":":white_check_mark: The repo has been updated!",
	      "color": 7844437,
	      "footer":{
	        "text":"Powered by MiguelNdeCarvalho"
	      },
	      "author":{
	        "name":"'$REPO_NAME' bot",
	        "icon_url":"https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Archlinux-icon-crystal-64.svg/1024px-Archlinux-icon-crystal-64.svg.png"
	      },
	      "fields":[
	        {
	          "name":"Changelog:",
	          "value":"```'$PACKAGE_LIST'```"
	        },
			{
	          "name":"Build time:",
	          "value":"'$1' minute(s) and '$2' seconds"
	        }
	      ]
	    }
	  ],
	  "username":"'$REPO_NAME' bot",
	  "avatar_url":"https://img.icons8.com/ultraviolet/240/000000/bot.png"
	}'

	curl -fsSL -H "Content-Type: application/json" -d "${response}" "${DISCORD_WEBHOOK}"
}

fail_notification ()
{
	response='
	{
	  "embeds":[
	    {
	      "description":":x: The repo couldn`t be update.",
	      "color": 14495300,
	      "footer":{
	        "text":"Powered by MiguelNdeCarvalho"
	      },
	      "author":{
	        "name":"'$REPO_NAME' bot",
	        "icon_url":"https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Archlinux-icon-crystal-64.svg/1024px-Archlinux-icon-crystal-64.svg.png"
	      },
	      "fields":[
	        {
	          "name":"Logs:",
	          "value":"[Click here]('$1')"
	        }
	      ]
	    }
	  ],
	  "username":"'$REPO_NAME' bot",
	  "avatar_url":"https://img.icons8.com/ultraviolet/240/000000/bot.png"
	}'
	
	curl -fsSL -H "Content-Type: application/json" -d "${response}" "${DISCORD_WEBHOOK}"
}

build ()
{
	BUILD_START=$(date +%s)
	if ! aur sync --no-view --noconfirm -d "${REPO_NAME}" -r "${REPO_PATH}" -R -u &> /tmp/update;then
		unset BUILD_START
		LOGS_URL=$(cat /tmp/update | hastebin)
		fail_notification "$LOGS_URL"
	else
		BUILD_END=$(date +%s)
		DIFF=$((BUILD_END - BUILD_START))
		success_notification "$((DIFF / 60))" "$((DIFF % 60))"
	fi
	rm /tmp/update
}

main ()
{
	HOME="/config"
	print_time "Starting repo update process"
	sudo pacman -Syu --noconfirm &> /dev/null #Update system
	build
	print_time "Finished repo update process"
}

main
