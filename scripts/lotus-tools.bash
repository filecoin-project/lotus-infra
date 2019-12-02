#!/usr/bin/env bash

# This is the name of the libp2p host key stored on disk in the lotus keystore
# See the lotus keystore implemenation for details
# base32 encoded string "libp2p-host" with zero padding
LIBP2P_KEYNAME="NRUWE4BSOAWWQ33TOQ"

log() {
  echo -e "\e[33m$1\e[39m"
}

error() {
  echo -e "\e[31m$1\e[39m"
  exit 1
}

if [ -z "$LOTUS_SRC" ]; then
  error '< LOTUS_SRC is not set'
fi

cmd_new_peerkey() {
  local host="$1"

  if [ -z "$host" ]
  then
    error '< No hostname provided to new_peerkey'
  fi
  
  log '> Moving to lotus repo'

  pushd "$LOTUS_SRC"

  log '> Generating new peerkey'

  LRPATH=$(mktemp -d)

  log 'Staring temp daemon'

  ./lotus --repo="${LRPATH}" daemon 2>/dev/null 1>/dev/null &
  LPID=$!

  sleep 3

  P2P_ADDRESS=$(./lotus --repo="${LRPATH}" net id)

  kill "$LPID"

  if [ ! -f "${LRPATH}/keystore/${LIBP2P_KEYNAME}" ]; then
    error '< Could not find libp2p key, did the keyname change?'
  fi

  log "New peerkey $P2P_ADDRESS for $host"

  P2P_KEYINFO=$(cat ${LRPATH}/keystore/${LIBP2P_KEYNAME})
 
  sed -i "/$host/c /dns4/$host/tcp/1347/p2p/$P2P_ADDRESS" build/bootstrap/bootstrappers.pi
  if ! grep "$host" build/bootstrap/bootstrappers.pi ; then
    echo "/dns4/$host/tcp/1347/p2p/$P2P_ADDRESS" >> build/bootstrap/bootstrappers.pi
  fi

  popd

  mkdir -p "ansible/host_vars/$host/"
  
  cat > "ansible/host_vars/$host/libp2p.vault.yml" <<EOF
  lotus_libp2p_keyinfo: $P2P_KEYINFO
  lotus_libp2p_address: $P2P_ADDRESS
EOF

  wait
}

cmd_new_genesis() {
  log '> Moving to lotus repo'

  pushd "$LOTUS_SRC"

  log '> Generating genesis'

  make

  GENPATH=$(mktemp -d)

  log 'Staring temp daemon'

  ./lotus --repo="${GENPATH}" daemon --lotus-make-random-genesis="${GENPATH}/devnet.car" 2>/dev/null 1>/dev/null &
  GDPID=$!

  sleep 3

  log 'Extracting genesis miner private key'

  WALLET_ADDR=$(./lotus --repo="${GENPATH}" wallet list)
  WALLET_KEYINFO=$(./lotus --repo="${GENPATH}" wallet export "$WALLET_ADDR")

  kill "$GDPID"

  wait

  log '> Creating genesis binary'

  cp "${GENPATH}/devnet.car" build/genesis/devnet.car

  log '> Updating genesis wallet.vault.yml'

  popd

  cat > ansible/group_vars/genesis/wallet.vault.yml <<EOF
lotus_wallet_keyinfo: $WALLET_KEYINFO
lotus_wallet_address: $WALLET_ADDR
EOF
}

cmd_build_binaries() {
  log '> Moving to lotus repo'

  pushd "$LOTUS_SRC"

  log '> Building lotus'

  make lotus

  log '> Building lotus-storage-miner'

  make lotus-storage-miner

  log '> Building fountain'

  make fountain
  
  log '> Moving binaries'

  cp lotus /tmp/lotus
  cp lotus-storage-miner /tmp/lotus-storage-miner
  cp fountain /tmp/lotus-fountain

  popd
}

main() {
  local cmd="$1"

  shift;

  case $cmd in
    "new-genesis")
      cmd_new_genesis $@
      ;;
    "new-peerkey")
      cmd_new_peerkey $@
      ;;
    "build-binaries")
      cmd_build_binaries $@
      ;;
  esac
}

main $@
