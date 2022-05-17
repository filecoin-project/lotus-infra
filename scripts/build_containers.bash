#!/usr/bin/env bash

set -xe

# Examples usages
#
# building a tagged release for the calibration network
# ./build_containers.bash --tag v1.5.0-pre1 --network calibnet
#
# building local source code
# ./build_containers.bash --src $GOPATH/src/github.com/filecoin-project/lotus --network calibnet
#
#
# if you need to override the docker tag, you can specify the `--docker-tag` flag

usage() {
  set +x
  echo "usage: build_containers.bash
    [--src        ] location of source code to build
    [--tag        ] tag to build
    [--docker-tag ] override the default docker tag of <network>-<commit|tag>
    [--network    ] name of network to build
    [--repo       ] docker repo to retag contains as and push
    [--native     ] build the filecoin ffi natively
    [--no-cache   ] pass the --no-cache flag to docker when building"
}

while [ "$1" != "" ]; do
    case $1 in
        --src )                 shift
                                src="$1"
                                ;;
        --tag )                 shift
                                tag="$1"
                                ;;
        --docker-tag )          shift
                                docker_tag="$1"
                                ;;
        --network )             shift
                                network="$1"
                                ;;
        --repo )                shift
                                repo="$1"
                                ;;
        --native )              native=true
                                ;;
        --no-cache )            nocache="--no-cache"
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
BUILD_REPO="${repo:-""}"
NETWORK="${network:-"mainnet"}"
DOCKER_NOCACHE="${nocache:-""}"

if ! docker info 2>&1 > /dev/null ; then
  echo "Docker is not running, or you do not have permission to execute commands"
  exit 1
fi

# Enable buildkit
export DOCKER_BUILDKIT=1

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$SCRIPTDIR/../docker"

goflags=(--build-arg=GOFLAGS="-tags='$NETWORK' -ldflags='-X=github.com/filecoin-project/lotus/build.NetworkBundle=$NETWORK'")

ffiargs=()
if [ "$BUILD_FFI" = true ]; then
  # If you need to build from source, but also need portable blst, set
  # FFI_USE_BLST_PORTABLE to 1
  ffiargs=(--build-arg=FFI_USE_BLST_PORTABLE="0" --build-arg=FFI_BUILD_FROM_SOURCE="1")
fi

buildargs=()
if [ ! -z "$BUILD_TAG" ]; then
  buildargs=(--build-arg=BUILDER_BASE=builder-git --build-arg=TAG=$BUILD_TAG)
  tag="$NETWORK-$BUILD_TAG"
else
  buildargs=(--build-arg=BUILDER_BASE=builder-local)
  tag="$NETWORK-$(git -C $BUILD_SRC describe --always --match=NeVeRmAtCh --dirty 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
fi

if [ -z $docker_tag ]; then
  docker_tag="$tag"
fi

docker build --progress=plain $DOCKER_NOCACHE -t "lotus:$docker_tag"            -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=lotus $(dirname $BUILD_SRC)
docker build --progress=plain $DOCKER_NOCACHE -t "lotus-shed:$docker_tag"       -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=shed $(dirname $BUILD_SRC)
docker build --progress=plain $DOCKER_NOCACHE -t "lotus-stats:$docker_tag"      -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=stats $(dirname $BUILD_SRC)
docker build --progress=plain $DOCKER_NOCACHE -t "lotus-miner:$docker_tag"      -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=miner $(dirname $BUILD_SRC)
docker build --progress=plain $DOCKER_NOCACHE -t "lotus-worker:$docker_tag"     -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=worker $(dirname $BUILD_SRC)
docker build --progress=plain $DOCKER_NOCACHE -t "lotus-gateway:$docker_tag"    -f Dockerfile.lotus "${ffiargs[@]}" "${goflags[@]}" "${buildargs[@]}" --target=gateway $(dirname $BUILD_SRC)

if [ ! -z "$BUILD_REPO" ]; then
  docker tag "lotus:$docker_tag"            "$BUILD_REPO/lotus:$docker_tag"
  docker tag "lotus-shed:$docker_tag"       "$BUILD_REPO/lotus-shed:$docker_tag"
  docker tag "lotus-stats:$docker_tag"      "$BUILD_REPO/lotus-stats:$docker_tag"
  docker tag "lotus-miner:$docker_tag"      "$BUILD_REPO/lotus-miner:$docker_tag"
  docker tag "lotus-worker:$docker_tag"     "$BUILD_REPO/lotus-worker:$docker_tag"
  docker tag "lotus-gateway:$docker_tag"     "$BUILD_REPO/lotus-gateway:$docker_tag"

  docker push "$BUILD_REPO/lotus:$docker_tag"
  docker push "$BUILD_REPO/lotus-shed:$docker_tag"
  docker push "$BUILD_REPO/lotus-stats:$docker_tag"
  docker push "$BUILD_REPO/lotus-miner:$docker_tag"
  docker push "$BUILD_REPO/lotus-worker:$docker_tag"
  docker push "$BUILD_REPO/lotus-gateway:$docker_tag"
fi

popd
