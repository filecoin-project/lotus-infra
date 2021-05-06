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
        -f | --build-ffi )      ffi=false
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

envflags=()
envflags+=(-e GOFLAGS="-tags=$tags")

ffiargs=()
if [ "$BUILD_FFI" = true ]; then
  ffiargs=(-e RUSTFLAGS="-C target-cpu=native -g" -e FFI_BUILD_FROM_SOURCE=1)
fi

sha=$(git describe --always --match=NeVeRmAtCh --dirty 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

docker build -t "lotus-binary-builder:$sha" -f Dockerfile.binarybuilder --build-arg UID="$(id -u)" .

volumes=(-v "$BUILD_SRC":/opt/build)
volumes+=(-v "lotusbinariesgomod:/go/pkg/mod")
volumes+=(-v "lotusbinariesgosum:/go/pkg/sumdb")

if [ $# -eq 0 ]; then
  buildlist=(clean lotus lotus-miner lotus-worker lotus-seed lotus-shed lotus-fountain lotus-stats lotus-chainwatch lotus-pcr)
else
  buildlist="$@"
fi

docker run --rm "${ffiargs[@]}" "${volumes[@]}" "${envflags[@]}" "lotus-binary-builder:$sha" ${buildlist[@]}

popd
