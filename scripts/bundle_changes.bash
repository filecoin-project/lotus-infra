#!/usr/bin/env bash

set -xe

pushd $1

tar -cvf "$2.tar" --files-from /dev/null

filelist=$(git status --porcelain --untracked-files=no | awk '{$1=$1};1' | awk '{print $2}')
for file in $filelist; do
  tar -rf "$2.tar" "$file"
done

popd
