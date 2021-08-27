#!/usr/bin/env bash

set -xe

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$SCRIPTDIR/../ansible"

filelist=$(git status --porcelain --untracked-files=no | awk '{$1=$1};1' | awk '{print $2}' | awk '/\.vault\.yml$/')
for file in $filelist; do
  ansible-vault encrypt ${file#ansible/}
done

popd
