#!/bin/bash

if [ -z "$1"];then
    echo -e "\e[31mYou forgot to pass the package name!\e[39m"
else
    echo -e "\e[33mRemoving${1} from repo!\e[39m"
    repo-remove /repo/"${REPO_NAME}".db.tar.xz "$1" &> /dev/null     
    rm -rf /repo/"$1"* &> /dev/null
    echo -e "\e[32mSucessfully removed ${1} from the repo!\e[39m"
fi
