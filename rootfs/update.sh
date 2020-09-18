#!/bin/bash

echo -e "\e[34m Updatig repo!\e[39m"
aur sync --no-view --noconfirm \
	-d ${REPO_NAME} \
	-r /repo \
	-R -u &> /dev/null
echo -e "\e[32m Repo sucessfully updated!\e[39m"
