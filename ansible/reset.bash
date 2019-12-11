#!/usr/bin/env bash

set -xe

ansible-playbook                                            \
  --vault-password-file .vault_password                     \
  -i bootstrap_miners lotus_bootstrap_miner.yml             \
  -e ansible_ssh_user=ubuntu                                \
  -e lotus_merge_sectors_binary_src=/tmp/lotus-seed         \
  -e lotus_merge_sectors_copy_binary=true                   \
  -e lotus_binary_src=/tmp/lotus                            \
  -e lotus_copy_binary=true                                 \
  -e lotus_miner_binary_src=/tmp/lotus-storage-miner        \
  -e lotus_miner_copy_binary=true                           \
  -e lotus_reset=yes                                        \
  -e lotus_miner_reset=yes -e lotus_daemon_bootstrap="true"

ansible --vault-password-file .vault_password all \
  -i bootstrap_miners                             \
  -e ansible_ssh_user=ubuntu                      \
  --become-method=sudo                            \
  --become                                        \
  -m systemd                                      \
  -a 'name=lotus-miner state=stopped'

ansible --vault-password-file .vault_password all \
  -i bootstrap_miners                             \
  -e ansible_ssh_user=ubuntu                      \
  --become-method=sudo                            \
  --become                                        \
  -m shell                                        \
  -a 'lotus net connect /dns4/t0222.miner.fil-test.net/tcp/1347/p2p/12D3KooWJgcCF8wBK5oUPrdGT4vZzBPYG1Td5QoJZDbUCMBQgSud | true'

ansible --vault-password-file .vault_password all \
  -i bootstrap_miners                             \
  -e ansible_ssh_user=ubuntu                      \
  --become-method=sudo                            \
  --become                                        \
  -m shell                                        \
  -a 'lotus net connect /dns4/t0333.miner.fil-test.net/tcp/1347/p2p/12D3KooWFFGEXXWNUS1xWo3GSWvyFfW1odryU6g3xx77rbdZQUXa | true'

ansible --vault-password-file .vault_password all \
  -i bootstrap_miners                             \
  -e ansible_ssh_user=ubuntu                      \
  --become-method=sudo                            \
  --become                                        \
  -m shell                                        \
  -a 'lotus net connect /dns4/t0444.miner.fil-test.net/tcp/1347/p2p/12D3KooWJhRvKcfFWKRjonZQgfy6TtRyNJgFAFpzDSrG3JDc72xz | true'

ansible --vault-password-file .vault_password all \
  -i bootstrap_miners                             \
  -e ansible_ssh_user=ubuntu                      \
  --become-method=sudo                            \
  --become                                        \
  -m shell                                        \
  -a 'lotus net peers'

ansible --vault-password-file .vault_password all \
  -i bootstrap_miners                             \
  -e ansible_ssh_user=ubuntu                      \
  --become-method=sudo                            \
  --become                                        \
  -m systemd                                      \
  -a 'name=lotus-miner-init state=started'

sleep 3

ansible --vault-password-file .vault_password all \
  -i bootstrap_miners                             \
  -e ansible_ssh_user=ubuntu                      \
  --become-method=sudo                            \
  --become                                        \
  -m shell                                        \
  -a 'systemctl status lotus-miner-init'

sleep 10

ansible --vault-password-file .vault_password all \
  -i bootstrap_miners                             \
  -e ansible_ssh_user=ubuntu                      \
  --become-method=sudo                            \
  --become                                        \
  -m shell                                        \
  -a 'tail -n25 /var/log/lotus-miner.log'

