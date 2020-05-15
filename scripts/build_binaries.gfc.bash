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
        -s | --src )            shift
                                src="$1"
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

GFC_SRC="${src:-"$GOPATH/src/github.com/filecoin-project/go-filecoin"}"
BUILD_FFI="${ffi:-""}"
PARAMETERS="${FIL_PROOFS_PARAMETER_CACHE:-"/var/tmp/filecoin-proof-parameters"}"

if ! docker info 2>&1 > /dev/null ; then
  echo "Docker is not running, or you do not have permission to execute commands"
  exit 1
fi

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$SCRIPTDIR/../docker"

ffiargs=()
if [ "$BUILD_FFI" = true ]; then
  ffiargs=(-e RUSTFLAGS="-C target-cpu=native -g" -e FFI_BUILD_FROM_SOURCE=1)
fi

sha=$(git describe --always --match=NeVeRmAtCh --dirty 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

docker build -t "gfc-binary-builder:$sha" -f Dockerfile.binarybuilder --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" .

# if GOPATH is set we will mount it for pkg/mod cache
# if GOPATH is not set, we'll check to see if the default exists, and set it
if [ -z "$GOPATH" ]; then
  if [ -d "$HOME/go/pkg/mod" ]; then
    GOPATH="$HOME/go"
  fi
fi

volumes=(-v "$GFC_SRC:/opt/filecoin")

# if GOPATH is set, we'll mount it
if [ ! -z "$GOPATH" ]; then
  volumes+=(-v "$GOPATH/pkg/mod:/go/pkg/mod")
  volumes+=(-v "$GOPATH/pkg/sumdb:/go/pkg/sumdb")
fi

volumes+=(-v "$PARAMETERS:/var/tmp/filecoin-proof-parameters")

docker run --rm "${ffiargs[@]}" "${volumes[@]}" "gfc-binary-builder:$sha" go run ./build deps
docker run --rm "${ffiargs[@]}" "${volumes[@]}" "gfc-binary-builder:$sha" go run ./build build

popd
