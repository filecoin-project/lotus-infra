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
        -b | --branch )         shift
                                branch=$1
                                ;;
        -c | --copy )           copy="True"
                                ;;
        -r | --restart )        restart="True"
                                ;;
        -k | --check )          check="--check"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

UPDATE_BRANCH="${branch:-"master"}"
COPY_BINARY="${copy:-"False"}"
RESTART_LOTUS="${restart:-"False"}"
ANSIBLE_CHECK_MODE="${check:- ""}"
LOTUS_SRC=$(mktemp -d)

if [ "$COPY_BINARY" = "True" ]; then
  git clone --branch $UPDATE_BRANCH https://github.com/filecoin-project/lotus.git $LOTUS_SRC

  pushd $LOTUS_SRC

  make clean deps lotus lotus-storage-miner

  popd
fi

HOSTS1=(
  t0222.miner.fil-test.net
  t0333.miner.fil-test.net
  t0444.miner.fil-test.net
)


HOSTS2=(
  lotus-fountain.yyz.fil-test.net
  stats.fil-test.net
  lotus-bootstrap-0.dfw.fil-test.net
  lotus-bootstrap-1.dfw.fil-test.net
  lotus-bootstrap-0.fra.fil-test.net
  lotus-bootstrap-1.fra.fil-test.net
  lotus-bootstrap-0.sin.fil-test.net
  lotus-bootstrap-1.sin.fil-test.net
)

for HOST in "${HOSTS1[@]}"; do
    ansible-playbook lotus_bootstrap_miner_update_binaries.yml        \
    -e lotus_binary_src="${LOTUS_SRC}/lotus"                          \
    -e lotus_miner_binary_src="${LOTUS_SRC}/lotus-storage-miner"      \
    -e lotus_copy_binary=$COPY_BINARY                                 \
    -e lotus_miner_copy_binary=$COPY_BINARY                           \
    -e lotus_daemon_restart=$RESTART_LOTUS                            \
    -e lotus_miner_restart=$RESTART_LOTUS                             \
    --limit $HOST                                                     \
    $ANSIBLE_CHECK_MODE                                               \
    $@

    read  -n 1 -p "Press any key to continue"
done

for HOST in "${HOSTS2[@]}"; do
    ansible-playbook lotus_bootstrap_miner_update_binaries.yml        \
    -e lotus_binary_src="${LOTUS_SRC}/lotus"                          \
    -e lotus_miner_binary_src="${LOTUS_SRC}/lotus-storage-miner"      \
    -e lotus_copy_binary=$COPY_BINARY                                 \
    -e lotus_daemon_restart=$RESTART_LOTUS                            \
    --limit $HOST                                                     \
    $ANSIBLE_CHECK_MODE                                               \
    $@

    read  -n 1 -p "Press any key to continue"
done
