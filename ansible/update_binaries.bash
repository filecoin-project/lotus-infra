#!/usr/bin/env bash

set -xe

UPDATE_BRANCH="master"
LOTUS_SRC=$(mktemp -d)

git fetch origin

git clone --branch $UPDATE_BRANCH https://github.com/filecoin-project/lotus.git $LOTUS_SRC

pushd $LOTUS_SRC

make clean deps lotus lotus-storage-miner

popd

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
    ansible-playbook --vault-password-file .vault_password            \
    -i testnet_hosts.yml lotus_bootstrap_miner_update_binaries.yml    \
    -e ansible_ssh_user=ubuntu                                        \
    -e lotus_binary_src="${LOTUS_SRC}/lotus"                          \
    -e lotus_miner_binary_src="${LOTUS_SRC}/lotus-storage-miner"      \
    -e lotus_copy_binary=True                                         \
    -e lotus_miner_copy_binary=True                                   \
  # -e lotus_daemon_restart=True                                      \
    --limit $HOST                                                     \                                                           \
    $@

    read  -n 1 -p "Press any key to continue"
done

for HOST in "${HOSTS2[@]}"; do
    ansible-playbook --vault-password-file .vault_password            \
    -i testnet_hosts.yml lotus_bootstrap_miner_update_binaries.yml    \
    -e ansible_ssh_user=root                                          \
    -e lotus_binary_src="${LOTUS_SRC}/lotus"                          \
    -e lotus_miner_binary_src="${LOTUS_SRC}/lotus-storage-miner"      \
    -e lotus_copy_binary=True                                         \
  # -e lotus_daemon_restart=True                                      \
    --limit $HOST                                                     \                                                       \
    $@

    read  -n 1 -p "Press any key to continue"
done
