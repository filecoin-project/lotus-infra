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
        --2k )                  smallsectors=true
                                ;;
        -f | --build-ffi )      ffi=true
                                ;;
        --network )             shift
                                network="$1"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        -- )                    shift
                                break
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

BUILD_SRC="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"
SMALL_SECTORS="${smallsectors:-""}"
BUILD_FFI="${ffi:-""}"
NETWORK="${network:-""}"

if ! docker info 2>&1 > /dev/null ; then
  echo "Docker is not running, or you do not have permission to execute commands"
  exit 1
fi

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$SCRIPTDIR/../docker"


gotags=()
if [ "$SMALL_SECTORS" = true ]; then
  gotags+=("2k")
fi

function join { local IFS="$1"; shift; echo "$*"; }

if [ ! -z $NETWORK ]; then
  gotags+=("${NETWORK}")
fi


tags=$(join , ${gotags[@]})

goflags=("-tags=$tags")
if [ ! -z $NETWORK ]; then
  goflags+=("-ldflags=-X=github.com/filecoin-project/lotus/build.NetworkBundle=${NETWORK}")
fi

envflags=()
# envflags+=(-e GOFLAGS="${goflags[@]}")

ffiargs=()
if [ "$BUILD_FFI" = true ]; then
  # If you need to build from source, but also need portable blst, set
  # FFI_USE_BLST_PORTABLE to 1
  ffiargs=(-e FFI_USE_BLST_PORTABLE=0 -e FFI_BUILD_FROM_SOURCE=1)
fi

sha=$(git describe --always --match=NeVeRmAtCh --dirty 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

docker build -t "lotus-binary-builder:$sha" -f Dockerfile.binarybuilder --build-arg UID="$(id -u)" .

# if GOPATH is set we will mount it for pkg/mod cache
# if GOPATH is not set, we'll check to see if the default exists, and set it
if [ -z "$GOPATH" ]; then
  if [ -d "$HOME/go/pkg/mod" ]; then
    GOPATH="$HOME/go"
  fi
fi

volumes=(-v "$BUILD_SRC":/opt/build)

# if GOPATH is set, we'll mount it
if [ ! -z "$GOPATH" ]; then
  volumes+=(-v "$GOPATH/pkg/mod:/go/pkg/mod")
  volumes+=(-v "$GOPATH/pkg/sumdb:/go/pkg/sumdb")
fi

if [ $# -eq 0 ]; then
  buildlist=(clean lotus lotus-miner lotus-worker lotus-seed lotus-shed lotus-fountain lotus-stats lotus-pcr)
else
  buildlist="$@"
fi

docker run --rm "${ffiargs[@]}" "${volumes[@]}" "${envflags[@]}" "lotus-binary-builder:$sha" ${buildlist[@]}

popd
