#!/usr/bin/env bash

set -xe

usage() {
  set +x
  echo "usage: update_binaries.bash
    [-b <branch> | --branch <branch>]
    [-c | --copy]
    [-r | --restart]
    [-k | --check]
    [-h | --help]"
}

while [ "$1" != "" ]; do
    case $1 in
        -s | --src )            shift
                                src="$1"
                                ;;
        -b | --branch )         shift
                                branch="$1"
                                ;;
        -c | --copy )           copy=true
                                ;;
        --state )               shift
                                state="$1"
                                ;;
        -k | --check )          check="--check"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        -- )                    shift; break
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

UPDATE_BRANCH="${branch:-"master"}"
LOTUS_SERVICE_STATE="${state:-"started"}"
ANSIBLE_CHECK_MODE="${check:-""}"
LOTUS_SRC="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"
hostfile="inventories/interopnet/hosts.yml"

../scripts/build_binaries.bash -f --src $LOTUS_SRC

HOSTS_MINERS=(
  "t01000.miner.interopnet.kittyhawk.wtf"
)

HOSTS_BOOTSTRAPPERS=(
  "peer0.interopnet.kittyhawk.wtf"
)

for HOST in "${HOSTS_MINERS[@]}"; do
    ansible-playbook -i $hostfile lotus_presealed_miner.yml           \
    -e lotus_binary_src="${LOTUS_SRC}/lotus"                          \
    -e lotus_miner_binary_src="${LOTUS_SRC}/lotus-storage-miner"      \
    -e lotus_service_state=$LOTUS_SERVICE_STATE                       \
    --limit "$HOST"                                                   \
    $ANSIBLE_CHECK_MODE                                               \
    "$@"

    read  -n 1 -p "Press any key to continue"
done

for HOST in "${HOSTS_BOOTSTRAPPERS[@]}"; do
    ansible-playbook -i $hostfile lotus_bootstrap.yml                 \
    -e lotus_binary_src="${LOTUS_SRC}/lotus"                          \
    -e lotus_miner_binary_src="${LOTUS_SRC}/lotus-storage-miner"      \
    -e lotus_service_state=$LOTUS_SERVICE_STATE                       \
    --limit "$HOST"                                                   \
    $ANSIBLE_CHECK_MODE                                               \
    "$@"

    read  -n 1 -p "Press any key to continue"
done
