#!/usr/bin/env bash

set -xe

ansible-playbook lotus_bootstrap_miner.yml                  \
  -e lotus_merge_sectors_binary_src=/tmp/lotus-seed         \
  -e lotus_merge_sectors_copy_binary=true                   \
  -e lotus_shed_binary_src=/tmp/lotus-shed                  \
  -e lotus_shed_copy_binary=true                            \
  -e lotus_binary_src=/tmp/lotus                            \
  -e lotus_copy_binary=true                                 \
  -e lotus_miner_binary_src=/tmp/lotus-storage-miner        \
  -e lotus_miner_copy_binary=true                           \
  -e lotus_reset=yes                                        \
  -e lotus_miner_reset=yes -e lotus_daemon_bootstrap="true"

ansible --vault-password-file .vault_password miners \
  --become                                        \
  -m systemd                                      \
  -a 'name=lotus-miner state=stopped'

ansible --vault-password-file .vault_password miners \
  --become                                        \
  -m shell                                        \
  -a 'lotus net connect /dns4/t0222.miner.fil-test.net/tcp/1347/p2p/12D3KooWNB9a7NrrLvMMxZR7kGRgwEjtHFE43APyf7pcQqFxY5gM | true'

ansible --vault-password-file .vault_password miners \
  --become                                        \
  -m shell                                        \
  -a 'lotus net connect /dns4/t0333.miner.fil-test.net/tcp/1347/p2p/12D3KooWK3W7mVL4yfUGST71V9Um54wVwWb8jmMLu3vW17gW8c3Y | true'

ansible --vault-password-file .vault_password miners \
  --become                                        \
  -m shell                                        \
  -a 'lotus net connect /dns4/t0444.miner.fil-test.net/tcp/1347/p2p/12D3KooWL4D6xmgEqaLsWR4Qdp11a6bbkJXrEkQsKde9NVtciqzT | true'

ansible --vault-password-file .vault_password miners \
  --become                                        \
  -m shell                                        \
  -a 'lotus net peers'

ansible --vault-password-file .vault_password miners \
  --become                                        \
  -m systemd                                      \
  -a 'name=lotus-miner-init state=started'

sleep 3

ansible --vault-password-file .vault_password miners \
  --become                                        \
  -m shell                                        \
  -a 'systemctl status lotus-miner-init'

sleep 10

ansible --vault-password-file .vault_password miners \
  --become                                        \
  -m shell                                        \
  -a 'tail -n1 /var/log/lotus-miner.log'

sleep 30

ansible --vault-password-file .vault_password miners \
  --become                                        \
  -m shell                                        \
  -a 'tail -n1 /var/log/lotus-miner.log'

# ^ Rerun the above till you see the message to run lotus-storage-miner run for all miners
# Then execute `systemctl start lotus-miner`
# Random Note: terraform/testnet
# Random Note: taint.sh
# Random Note: terraform12 plan -out plan.tfplan -var 'lotus_copy_binary=true' -var 'lotus_fountain_copy_binary=true' -var 'lotus_reset=yes'
# Random Note: Login to the fountain and create a wallet `lotus wallet new`, copy the key to `/etc/systemd/system/lotus-fountain.service
# Random Note: and replace `replaceme`, systemctl daemon-reload, systemctl restart lotus-fountain


