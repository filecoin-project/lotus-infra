#!/usr/bin/env bash

set -xe

genesis="10.10.100.100"
hosts=("10.10.100.100" "10.10.100.101")
hostfile="inventories/vagrant/hosts.yml"
faucetaddr="t1tz6t3xuk3s5b5jj727kz3m6kzprxicarb4dhlmq"
faucetbalance="1000000000000000000000"

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
        --skip-first-build )    skip=true
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
SKIP_FIRST_BUILD="${skip:-""}"
NETWORKNAME="interop"

pushd "$LOTUS_SRC"
make lotus-shed
truncate -s 0 build/bootstrap/bootstrappers.pi
popd

for host in ${hosts[@]}; do
  pushd "$LOTUS_SRC"
  P2P_ADDRESS=$(./lotus-shed peerkey)
  P2P_KEYINFO=$(cat ${P2P_ADDRESS}.peerkey)
  rm ${P2P_ADDRESS}.peerkey

  sed -i "/$host/c /ip4/$host/tcp/1347/p2p/$P2P_ADDRESS" build/bootstrap/bootstrappers.pi
  if ! grep "$host" build/bootstrap/bootstrappers.pi ; then
    echo "/ip4/$host/tcp/1347/p2p/$P2P_ADDRESS" >> build/bootstrap/bootstrappers.pi
  fi
  popd

  mkdir -p "$(dirname $hostfile)/host_vars/$host/"

  cat > "$(dirname $hostfile)/host_vars/$host/libp2p.vault.yml" <<EOF
libp2p_keyinfo: $P2P_KEYINFO
libp2p_address: $P2P_ADDRESS
EOF

done

if [ -z "$SKIP_FIRST_BUILD" ]; then
  ../scripts/build_binaries.bash --2k
fi

if [ "$PRESEAL" = true ]; then
  vagrant snapshot restore vagrant0 provisioned --no-provision
  vagrant snapshot restore vagrant1 provisioned --no-provision

  ansible-playbook -i $hostfile lotus_presealing.yml                                                   \
                   -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed" \
                   -e lotus_seed_reset="${RESET}"                                                      \
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
                 -e lotus_daemon_bootstrap=false                                                               \
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

../scripts/build_binaries.bash --src "$LOTUS_SRC" --2k

ansible-playbook -i $hostfile lotus_presealed_miner.yml                                                        \
                 -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=false                                                               \
                 "$@"

sleep 30

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

ansible-playbook -i $hostfile lotus_stats.yml                                                                  \
                 -e stats_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/stats"                     \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=false                                                               \
                 -e stats_reset=${RESET}                                                                       \
                 -e chainwatch_reset=${RESET}                                                                  \
                 -e chainwatch_db_reset=yes                                                                    \
                 "$@"

ansible-playbook -i $hostfile lotus_fountain.yml                                                               \
                 -e lotus_fountain_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/fountain"         \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=false                                                               \
                 -e lotus_import_wallet=true                                                                   \
                 -e lotus_fountain_enabled=true                                                                \
                 "$@"
