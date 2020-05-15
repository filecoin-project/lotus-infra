#!/usr/bin/env bash

set -xe

genesis="t01000.miner.fil-test.net"
miners=("$genesis" "t01001.miner.fil-test.net" "t01002.miner.fil-test.net" "t01003.miner.fil-test.net")
bootstrappers=("bootstrap-0-sin.fil-test.net" "bootstrap-0-dfw.fil-test.net" "bootstrap-0-fra.fil-test.net" "bootstrap-1-sin.fil-test.net" "bootstrap-1-dfw.fil-test.net" "bootstrap-1-fra.fil-test.net")
hostfile="inventories/testnet/hosts.yml"
faucetaddr="t1hw4amnow4gsgk2ottjdpdverfwhaznyrslsmoni"
faucetbalance="256000000000000000000000000"
GENESISTIMESTAMP="2020-05-14T22:00:00Z"

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
NETWORKNAME="testnet"

pushd "$LOTUS_SRC"
truncate -s 0 build/bootstrap/bootstrappers.pi
popd

for host in ${bootstrappers[@]}; do
  pushd "$LOTUS_SRC"
  P2P_ADDRESS=$(./lotus-shed peerkey)
  set +x
  P2P_KEYINFO=$(cat ${P2P_ADDRESS}.peerkey)
  set -x
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
../scripts/build_binaries.gfc.bash -f

ansible-playbook -i $hostfile lotus_presealed_miner.yml                                                        \
                 -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
                 -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"           \
                 -e lotus_miner_import_wallet=true                                                             \
                 -e lotus_import_peerkey=true                                                                  \
                 -e lotus_daemon_bootstrap=true                                                                \
                 -e lotus_service_state=stopped                                                                \
                 -e lotus_miner_reset="${RESET}"                                                               \
                 -e lotus_reset="${RESET}"                                                                     \
                 -e lotus_miner_ensure_params=false                                                            \
                 "$@"

PRESEALPATH=$(mktemp -d)

ansible -i $hostfile -b -m fetch -a "src=/tmp/presealed-metadata.json dest=${PRESEALPATH}" presealed_miners_all

pushd "$LOTUS_SRC"

GENPATH=$(mktemp -d)

./lotus-seed genesis new "${GENPATH}/genesis.json"

for m in "${miners[@]}"; do
  ./lotus-seed genesis add-miner "${GENPATH}/genesis.json" "${PRESEALPATH}/${m}/tmp/presealed-metadata.json"
done

GENESISTMP=$(mktemp)

#GENESISTIMESTAMP=$(date --utc +%FT%H:%M:00Z)
TIMESTAMP=$(echo $(date -d ${GENESISTIMESTAMP} +%s) + ${GENESISDELAY} | bc)

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

sleep 30

kill "$GDPID"

wait

cp "${GENPATH}/testnet.car" build/genesis/devnet.car

popd

../scripts/build_binaries.bash -f --src "$LOTUS_SRC"

ansible-playbook -i $hostfile lotus_bootstrap.yml                                                              \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
                 -e lotus_daemon_bootstrap=true                                                                \
                 -e lotus_import_peerkey=true                                                                  \
                 -e lotus_service_state=started                                                                \
                 -e lotus_reset="${RESET}"                                                                     \
                 "$@"

ansible-playbook -i $hostfile gfc_bootstrap.yml                                                                \
                 -e gfc_lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"       \
                 -e gfc_bootstrap_list_src="$GOPATH/src/github.com/filecoin-project/lotus/build/bootstrap/bootstrappers.pi" \
                 -e gfc_binary_src="$GOPATH/src/github.com/filecoin-project/go-filecoin/go-filecoin"           \
                 -e gfc_genesis_src="$GOPATH/src/github.com/filecoin-project/lotus/build/genesis/devnet.car"   \
                 -e gfc_service_state=started                                                                  \
                 -e gfc_block_time=25s                                                                         \
                 -e gfc_reset=${RESET}                                                                         \
                 "$@"

sleep 30

ansible-playbook -i $hostfile lotus_stats.yml                                                                  \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e stats_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/stats"                     \
                 -e chainwatch_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/chainwatch"           \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=true                                                                \
                 -e chainwatch_reset=${RESET}                                                                  \
                 -e stats_reset=${RESET}                                                                       \
                 -e lotus_reset=${RESET}                                                                       \
                 "$@"

ansible-playbook -i $hostfile lotus_fountain.yml                                                               \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_fountain_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/fountain"         \
                 -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=true                                                                \
                 -e lotus_import_wallet=true                                                                   \
                 -e lotus_fountain_enabled=false                                                               \
                 -e lotus_reset=${RESET}                                                                       \
                 "$@"

sleep 30

ansible-playbook -i $hostfile lotus_presealed_miner.yml                                                        \
                 -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_service_state=started                                                                \
                 -e lotus_miner_ensure_params=false                                                            \
                 -e lotus_daemon_bootstrap=true                                                                \
                 "$@"

sleep 30

ansible -i $hostfile -b -m shell -a 'lotus chain list'                          presealed_miners
ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner-init'          presealed_miners

date -d @${TIMESTAMP} --utc +%FT%H:%M:%SZ

exit 0

DELAY=$(echo "${TIMESTAMP} - $(date +%s) " | bc)

sleep $DELAY

ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init || true' $genesis

sleep 75

ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init || true' $genesis

sleep 5

ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init || true' $genesis

sleep 5

ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner'               presealed_miners

sleep 75

ansible -i $hostfile -b -m shell -a 'lotus chain list'                          presealed_miners

sleep 30

ansible-playbook -i $hostfile lotus_fountain.yml -e lotus_fountain_enabled=true -e lotus_service_state=started
