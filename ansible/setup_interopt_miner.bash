#!/usr/bin/env bash

set -xe

genesis="t01000.miner.interopnet.kittyhawk.wtf"
hosts=("$genesis" "peer0.interopnet.kittyhawk.wtf" "peer1.interopnet.kittyhawk.wtf")
hostfile="inventories/interopnet/hosts.yml"
faucetaddr="t1wn6ayeny3hh425lcatf5i7a3pvjwwncri67moni"
faucetbalance="5000000000000000000000000"

while [ "$1" != "" ]; do
    case $1 in
        -s | --src )            shift
                                src="$1"
                                ;;
        -p | --preseal )        preseal=true
                                ;;
        -r | --reset )          reset="yes"
                                ;;
        --delay )               shift
                                genesisdelay="$1"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        -- )                    shift; break
                                ;;
    esac
    shift
done

LOTUS_SRC="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"
GENESISDELAY="${genesisdelay:-"600"}"
PRESEAL="${preseal:-""}"
RESET="${reset:-"no"}"
NETWORKNAME="interop"

pushd "$LOTUS_SRC"
truncate -s 0 build/bootstrap/bootstrappers.pi
popd

for host in ${hosts[@]}; do
  pushd "$LOTUS_SRC"
  P2P_ADDRESS=$(./lotus-shed peerkey)
  P2P_KEYINFO=$(cat ${P2P_ADDRESS}.peerkey)
  rm ${P2P_ADDRESS}.peerkey

  # sed -i "/$host/c /dns4/$host/tcp/1347/p2p/$P2P_ADDRESS" build/bootstrap/bootstrappers.pi
  if ! grep "$host" build/bootstrap/bootstrappers.pi ; then
    echo "/dns4/$host/tcp/1347/p2p/$P2P_ADDRESS" >> build/bootstrap/bootstrappers.pi
    echo "/ip4/$(dig +short $host)/tcp/1347/p2p/$P2P_ADDRESS" >> build/bootstrap/bootstrappers.pi
  fi
  popd

  mkdir -p "$(dirname $hostfile)/host_vars/$host/"

  cat > "$(dirname $hostfile)/host_vars/$host/libp2p.vault.yml" <<EOF
libp2p_keyinfo: $P2P_KEYINFO
libp2p_address: $P2P_ADDRESS
EOF

done

../scripts/build_binaries.bash -f --src "$LOTUS_SRC"

if [ "$PRESEAL" = true ]; then
  ansible-playbook -i $hostfile lotus_presealing.yml                                                   \
                   -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed" \
                   -e lotus_seed_reset=yes                                                             \
                   "$@"

  ansible -i $hostfile -b -m shell -a 'systemctl start lotus-seed-0' $genesis
  ansible -i $hostfile -b -m shell -a 'systemctl start lotus-seed-1' $genesis

  echo "Check presealing status"
  echo "ansible -i $hostfile -b -m shell -a 'systemctl status lotus-seed-0' $genesis"
  echo "ansible -i $hostfile -b -m shell -a 'systemctl status lotus-seed-1' $genesis"

  read  -n 1 -p "Press any key to continue"
fi

ansible-playbook -i $hostfile lotus_presealed_miner.yml                                                        \
                 -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
                 -e lotus_miner_import_wallet=true                                                             \
                 -e lotus_import_peerkey=true                                                                  \
                 -e lotus_daemon_bootstrap=true                                                                \
                 -e lotus_service_state=stopped                                                                \
                 -e lotus_miner_reset="${RESET}"                                                               \
                 -e lotus_reset="${RESET}"                                                                     \
                 "$@"

PRESEALPATH=$(mktemp -d)

ansible -i $hostfile -b -m fetch -a "src=/tmp/presealed-metadata.json dest=${PRESEALPATH}" $genesis

pushd "$LOTUS_SRC"

SEEDPATH=$(mktemp -d)

./lotus-seed aggregate-manifests "${PRESEALPATH}/$genesis/tmp/presealed-metadata.json" > "${SEEDPATH}/miner.json"

GENPATH=$(mktemp -d)

./lotus-seed genesis new "${GENPATH}/genesis.json"
./lotus-seed genesis add-miner "${GENPATH}/genesis.json" "${SEEDPATH}/miner.json"

GENESISTMP=$(mktemp)

TIMESTAMP=$(echo $(date -d $(date --utc +%FT%H:%M:00Z) +%s) + ${GENESISDELAY} | bc)

jq --arg Timestamp ${TIMESTAMP} ' . + { Timestamp: $Timestamp|tonumber } ' < "${GENPATH}/genesis.json" > ${GENESISTMP}
mv ${GENESISTMP} "${GENPATH}/genesis.json"

jq --arg NetworkName ${NETWORKNAME} ' .NetworkName = $NetworkName ' < "${GENPATH}/genesis.json" > ${GENESISTMP}
mv ${GENESISTMP} "${GENPATH}/genesis.json"

jq --arg Owner ${faucetaddr} --arg Balance ${faucetbalance}  '.Accounts |= . + [{Type: "account", Balance: $Balance, Meta: {Owner: $Owner}}]' < "${GENPATH}/genesis.json" > ${GENESISTMP}
mv ${GENESISTMP} "${GENPATH}/genesis.json"

./lotus --repo="${GENPATH}" daemon --api 0 --lotus-make-genesis="${GENPATH}/testnet.car" --genesis-template="${GENPATH}/genesis.json" --bootstrap=false &
GDPID=$!

while true; do
  if [ ! -f "${GENPATH}/testnet.car" ]; then
    sleep 5
  else
    break
  fi
done

kill "$GDPID"

wait

sleep 30

cp "${GENPATH}/testnet.car" build/genesis/devnet.car

popd

../scripts/build_binaries.bash -f --src "$LOTUS_SRC"

ansible-playbook -i $hostfile lotus_presealed_miner.yml                                                        \
                 -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=true                                                                \
                 "$@"

sleep 30

ansible -i $hostfile -b -m shell -a 'lotus net id'                              $genesis

ansible -i $hostfile -b -m shell -a 'lotus chain list'                          $genesis
ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner-init'          $genesis

date -d @${TIMESTAMP} --utc +%FT%H:%M:%SZ

sleep 30

ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init || true' $genesis

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init || true' $genesis

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner'               $genesis
ansible -i $hostfile -b -m shell -a 'lotus chain list'                          $genesis

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'lotus chain list'                          $genesis

ansible-playbook -i $hostfile lotus_bootstrap.yml                                                              \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
                 -e lotus_daemon_bootstrap=true                                                                \
                 -e lotus_import_peerkey=true                                                                  \
                 -e lotus_service_state=started                                                                \
                 -e lotus_reset="${RESET}"                                                                     \
                 "$@"

sleep 5

ansible-playbook -i $hostfile lotus_stats.yml                                                                  \
                 -e stats_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/stats"                     \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=false                                                               \
                 -e stats_reset=${RESET}                                                                       \
                 "$@"

ansible-playbook -i $hostfile lotus_chainwatch.yml                                                             \
                 -e chainwatch_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/chainwatch"           \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=false                                                               \
                 -e chainwatch_reset=${RESET}                                                                  \
                 "$@"

ansible-playbook -i $hostfile lotus_fountain.yml                                                               \
                 -e lotus_fountain_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/fountain"         \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=false                                                               \
                 -e lotus_import_wallet=true                                                                   \
                 -e lotus_fountain_enabled=true                                                                \
                 "$@"
