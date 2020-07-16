#!/usr/bin/bash

set -xe

miners=("t01000" "t01001" "t01002")

for miner in ${miners[@]}; do
  BLS_ADDRESS=$(lotus-shed keyinfo new bls)
  BLS_KEYINFO=$(cat bls-${BLS_ADDRESS}.keyinfo)
  rm "bls-${BLS_ADDRESS}.keyinfo"

  cat > "group_vars/$miner/lotus_miner.vault.yml" <<EOF
vault_lotus_miner_wallet_keyinfo: $BLS_KEYINFO
vault_lotus_miner_wallet_address: $BLS_ADDRESS
EOF
done
