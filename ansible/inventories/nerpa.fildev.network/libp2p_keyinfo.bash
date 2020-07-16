#!/usr/bin/bash

set -xe

for host in $(ls host_vars); do
  P2P_ADDRESS=$(lotus-shed keyinfo new libp2p-host)
  P2P_KEYINFO=$(cat libp2p-host-${P2P_ADDRESS}.keyinfo)
  rm "libp2p-host-${P2P_ADDRESS}.keyinfo"

  cat > "host_vars/$host/libp2p.vault.yml" <<EOF
libp2p_keyinfo: $P2P_KEYINFO
libp2p_address: $P2P_ADDRESS
EOF
done
