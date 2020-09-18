#!/bin/bash

repo-remove /repo/"${REPO_NAME}".db.tar.xz "$1"       
rm -rf /repo/"$1"*
