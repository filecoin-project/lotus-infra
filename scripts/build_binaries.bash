#!/usr/bin/env bash

set -xe

usage() {
  set +x
  echo "usage: build_binaries.bash
    [-s <src> | --src <src>]
    [-d | --debug]
    [-h | --help]"
}

while [ "$1" != "" ]; do
    case $1 in
        -s | --src )         shift
                                src="$1"
                                ;;
        -d | --debug )          debug=true
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

LOTUS_SRC="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"
DEBUG_BUILD="${debug:-""}"

if ! docker info 2>&1 > /dev/null ; then
  echo "Docker is not running, or you do not have permission to execute commands"
  exit 1
fi

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$SCRIPTDIR/../docker"

if [ "$DEBUG_BUILD" = true ]; then
  buildlist=(debug lotus-shed fountain stats chainwatch)
else
  buildlist=(lotus lotus-storage-miner lotus-seal-worker lotus-seed lotus-shed fountain stats chainwatch)
fi

sha=$(git describe --always --match=NeVeRmAtCh --dirty 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

docker build -t "lotus-binary-builder:$sha" -f Dockerfile.binarybuilder --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" .

# if GOPATH is set we will mount it for pkg/mod cache
# if GOPATH is not set, we'll check to see if the default exists, and set it
if [ -z "$GOPATH" ]; then
  if [ -d "$HOME/go/pkg/mod" ]; then
    GOPATH="$HOME/go"
  fi
fi

# if GOPATH is not set, we'll skip mounting
if [ -z "$GOPATH" ]; then
  docker run --rm -v "$LOTUS_SRC:/opt/lotus" "lotus-binary-builder:$sha" make "${buildlist[@]}"
else
  docker run --rm -v "$LOTUS_SRC:/opt/lotus" -v "$GOPATH/pkg/mod:/go/pkg/mod" "lotus-binary-builder:$sha" make "${buildlist[@]}"
fi

popd
