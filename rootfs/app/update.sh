#!/usr/bin/with-contenv bash
# shellcheck shell=bash



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

noupdates_notification ()
{
	response='
	{
	  "embeds":[
	    {
	      "description":":warning: There are no updates available!",
	      "color": 16312092,
	      "footer":{
	        "text":"Powered by MiguelNdeCarvalho"
	      },
	      "author":{
	        "name":"'$REPO_NAME' bot",
	        "icon_url":"https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Archlinux-icon-crystal-64.svg/1024px-Archlinux-icon-crystal-64.svg.png"
	      }
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

update ()
{
	BUILD_START=$(date +%s)
	aur sync --no-view --noconfirm -d "${REPO_NAME}" -r "${REPO_PATH}" -R -u &> /tmp/update
	EXIT_CODE="$?"
	if [ "$EXIT_CODE" == '0' ];then
		BUILD_END=$(date +%s)
		DIFF=$((BUILD_END - BUILD_START))
		success_notification "$((DIFF / 60))" "$((DIFF % 60))"
	elif [ "$EXIT_CODE" == '123' ];then
		unset BUILD_START
		noupdates_notification
	else
		unset BUILD_START
		LOGS_URL=$(cat /tmp/update | hastebin)
		fail_notification "$LOGS_URL"
	fi
	rm /tmp/update
}

main ()
{
	HOME="/config"
	REPO_PATH="/config/repo"
	sudo pacman -Syu --noconfirm &> /dev/null #Update system
	update
	sudo pacman -Scc --noconfirm &> /dev/null #Clean cache
}

main
