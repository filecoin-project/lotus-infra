#!/usr/bin/env bash

set -xe

DOCKER_REGISTERY="657871693752.dkr.ecr.us-east-1.amazonaws.com"

rm -rf ./work || true
mkdir -p ./work
pushd ./work

git clone git@github.com:filecoin-project/lotus.git

pushd ./lotus
git checkout "$1"
popd

docker build -t builder:latest     -f ../docker/Dockerfile.builder .
docker build -t stats-lotus:latest -f ../docker/Dockerfile.lotus . --cache-from builder:latest
docker build -t stats-stats:latest -f ../docker/Dockerfile.stats . --cache-from builder:latest

docker tag stats-lotus:latest $DOCKER_REGISTERY/stats-lotus:latest
docker tag stats-stats:latest $DOCKER_REGISTERY/stats-stats:latest

docker push $DOCKER_REGISTERY/stats-lotus:latest
docker push $DOCKER_REGISTERY/stats-stats:latest

popd
