#!/usr/bin/env bash

set -xe

usage() {
  set +x
  echo "usage: build_binaries.bash
    [--src    ] location of source code to build
    [--tag    ] tag to build
    [--native ] build the filecoin ffi natively"
}

while [ "$1" != "" ]; do
    case $1 in
        --src )                 shift
                                src="$1"
                                ;;
        --tag )                 shift
                                tag="$1"
                                ;;
        --native )              native=true
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
BUILD_FFI="${native:-""}"
BUILD_TAG="${tag:-""}"

if ! docker info 2>&1 > /dev/null ; then
  echo "Docker is not running, or you do not have permission to execute commands"
  exit 1
fi

# Enable buildkit
export DOCKER_BUILDKIT=1

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$SCRIPTDIR/../docker"

goflags=()
ffiargs=()
if [ "$BUILD_FFI" = true ]; then
  ffiargs=(-e RUSTFLAGS="-C target-cpu=native -g" -e FFI_BUILD_FROM_SOURCE=1)
fi

buildargs=()
if [ ! -z "$BUILD_TAG" ]; then
  buildargs=(--build-arg=BUILDER_BASE=builder-git --build-arg=TAG=$BUILD_TAG)
  tag="$BUILD_TAG"
else
  buildargs=(--build-arg=BUILDER_BASE=builder-local)
  tag=$(git -C $BUILD_SRC describe --always --match=NeVeRmAtCh --dirty 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
fi

docker build -t "lotus:$tag"            -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=lotus $(dirname $BUILD_SRC)
docker build -t "lotus-shed:$tag"       -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=shed $(dirname $BUILD_SRC)
docker build -t "lotus-miner:$tag"      -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=miner $(dirname $BUILD_SRC)
docker build -t "lotus-worker:$tag"     -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=worker $(dirname $BUILD_SRC)
docker build -t "lotus-chainwatch:$tag" -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=chainwatch $(dirname $BUILD_SRC)

docker tag "lotus:$tag"            "$DOCKER_REPO/lotus:$tag"
docker tag "lotus-shed:$tag"       "$DOCKER_REPO/lotus-shed:$tag"
docker tag "lotus-miner:$tag"      "$DOCKER_REPO/lotus-miner:$tag"
docker tag "lotus-worker:$tag"     "$DOCKER_REPO/lotus-worker:$tag"
docker tag "lotus-chainwatch:$tag" "$DOCKER_REPO/lotus-chainwatch:$tag"

docker push "$DOCKER_REPO/lotus:$tag"
docker push "$DOCKER_REPO/lotus-shed:$tag"
docker push "$DOCKER_REPO/lotus-miner:$tag"
docker push "$DOCKER_REPO/lotus-worker:$tag"
docker push "$DOCKER_REPO/lotus-chainwatch:$tag"

docker tag "lotus:$tag"            "$DOCKER_REPO/lotus:latest"
docker tag "lotus-shed:$tag"       "$DOCKER_REPO/lotus-shed:latest"
docker tag "lotus-miner:$tag"      "$DOCKER_REPO/lotus-miner:latest"
docker tag "lotus-worker:$tag"     "$DOCKER_REPO/lotus-worker:latest"
docker tag "lotus-chainwatch:$tag" "$DOCKER_REPO/lotus-chainwatch:latest"

docker push "$DOCKER_REPO/lotus:latest"
docker push "$DOCKER_REPO/lotus-shed:latest"
docker push "$DOCKER_REPO/lotus-miner:latest"
docker push "$DOCKER_REPO/lotus-worker:latest"
docker push "$DOCKER_REPO/lotus-chainwatch:latest"

popd
