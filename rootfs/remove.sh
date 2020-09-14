#!/bin/bash

repo-remove /repo/"${REPO_NAME}".db.tar.xz "$1"       
rm local-repo/"$1"-*.pkg.tar.xz
