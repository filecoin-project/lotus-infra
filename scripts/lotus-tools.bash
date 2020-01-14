#!/usr/bin/env bash

set -xe

# This is the name of the libp2p host key stored on disk in the lotus keystore
# See the lotus keystore implemenation for details
# base32 encoded string "libp2p-host" with zero padding
LIBP2P_KEYNAME="NRUWE4BSOAWWQ33TOQ"
GENESISTIMESTAMP="2020-01-14T01:00:00Z"

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

  ./lotus --repo="${LRPATH}" daemon --bootstrap=false 2>/dev/null 1>/dev/null &
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
  log '> Moving manifests file to tmp path'

  PRESEALPATH=$(mktemp -d)
  cp presealed/pre-seal-t0222.json presealed/pre-seal-t0333.json presealed/pre-seal-t0444.json "${PRESEALPATH}"

  log '> Moving to lotus repo'

  pushd "$LOTUS_SRC"

  log '> Generating genesis'

  make clean lotus lotus-seed

  log 'Aggregating manifests'

  SEEDPATH=$(mktemp -d)

  ./lotus-seed aggregate-manifests "${PRESEALPATH}/pre-seal-t0222.json" "${PRESEALPATH}/pre-seal-t0333.json" "${PRESEALPATH}/pre-seal-t0444.json" > "${SEEDPATH}/genesis.json"

  GENPATH=$(mktemp -d)

  log 'Staring temp daemon'


  ./lotus --repo="${GENPATH}" daemon --genesis-timestamp="${GENESISTIMESTAMP}" --lotus-make-random-genesis="${GENPATH}/testnet.car" --genesis-presealed-sectors="${SEEDPATH}/genesis.json" --bootstrap=false &
  GDPID=$!

  sleep 3

  kill "$GDPID"

  wait

  log '> Creating genesis binary'

  cp "${GENPATH}/testnet.car" build/genesis/devnet.car

  popd
}

cmd_make_fountain_wallet() {
  log '> Moving to lotus repo'

  pushd "$LOTUS_SRC"

  make clean lotus

  log 'Staring temp daemon'

  GENPATH=$(mktemp -d)

  ./lotus --repo="${GENPATH}" daemon --bootstrap=false 2>/dev/null 1>/dev/null &
  GDPID=$!

  sleep 3

  ./lotus --repo="${GENPATH}" wallet new

  log 'Extracting wallet private key'

  WALLET_ADDR=$(./lotus --repo="${GENPATH}" wallet list)
  WALLET_KEYINFO=$(./lotus --repo="${GENPATH}" wallet export "$WALLET_ADDR")

  kill "$GDPID"

  wait

  popd

  cat > ansible/host_vars/lotus-fountain.fil-test.net/wallet.vault.yml <<EOF
lotus_wallet_keyinfo: $WALLET_KEYINFO
lotus_wallet_address: $WALLET_ADDR
EOF
}

cmd_build_binaries() {
  log '> Moving to lotus repo'

  pushd "$LOTUS_SRC"

  log '> Building lotus'

  make clean
  make lotus

  log '> Building lotus-storage-miner'

  make lotus-storage-miner

  log '> Building fountain'

  make fountain

  log '> Building lotus-shed'

  make lotus-shed

  log '> Building lotus-seed'

  make lotus-seed

  log '> Moving binaries'

  cp lotus /tmp/lotus
  cp lotus-storage-miner /tmp/lotus-storage-miner
  cp fountain /tmp/lotus-fountain
  cp lotus-shed /tmp/lotus-shed
  cp lotus-seed /tmp/lotus-seed

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
    "make-fountain-wallet")
      cmd_make_fountain_wallet $@
      ;;
  esac
}

main $@
