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

LOTUS_SRC="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"
SMALL_SECTORS="${smallsectors:-""}"
BUILD_FFI="${ffi:-""}"

if ! docker info 2>&1 > /dev/null ; then
  echo "Docker is not running, or you do not have permission to execute commands"
  exit 1
fi

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$SCRIPTDIR/../docker"

goflags=()

if [ "$SMALL_SECTORS" = true ]; then
  goflags+=(-e GOFLAGS="-tags=2k")
fi

ffiargs=()
if [ "$BUILD_FFI" = true ]; then
  ffiargs=(-e RUSTFLAGS="-C target-cpu=native -g" -e FFI_BUILD_FROM_SOURCE=1)
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

volumes=(-v "$LOTUS_SRC:/opt/filecoin")

# if GOPATH is set, we'll mount it
if [ ! -z "$GOPATH" ]; then
  volumes+=(-v "$GOPATH/pkg/mod:/go/pkg/mod")
  volumes+=(-v "$GOPATH/pkg/sumdb:/go/pkg/sumdb")
fi

if [ $# -eq 0 ]; then
  buildlist=(lotus lotus-miner lotus-seal-worker lotus-seed lotus-shed lotus-fountain lotus-stats lotus-chainwatch)
else
  buildlist="$@"
fi

docker run --rm "${ffiargs[@]}" "${volumes[@]}" "${goflags[@]}" "lotus-binary-builder:$sha" make clean deps ${buildlist[@]}

popd
