#!/usr/bin/env bash

set -xe

host="t01000.miner.interopnet.kittyhawk.wtf"
hostfile="inventories/interopnet/hosts.yml"
faucetaddr="t1wn6ayeny3hh425lcatf5i7a3pvjwwncri67moni"
faucetbalance="5000000000000000000000000"

while [ "$1" != "" ]; do
    case $1 in
        -s | --src )            shift
                                src="$1"
                                ;;
        -d | --debug )          debug=true
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
DEBUG_BUILD="${debug:-""}"
PRESEAL="${preseal:-""}"
RESET="${reset:-"no"}"
NETWORKNAME="interop"

../scripts/build_binaries.bash --src "$LOTUS_SRC"


if [ "$PRESEAL" = true ]; then
  ansible-playbook -i $hostfile lotus_presealing.yml                                                   \
                   -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed" \
                   -e lotus_seed_reset="${RESET}"                                                      \
                   "$@"

  ansible -i $hostfile -b -m shell -a 'systemctl start lotus-seed-0' $host
  ansible -i $hostfile -b -m shell -a 'systemctl start lotus-seed-1' $host

  echo "Check presealing status"
  echo "ansible -i $hostfile -b -m shell -a 'systemctl status lotus-seed-0' $host"
  echo "ansible -i $hostfile -b -m shell -a 'systemctl status lotus-seed-1' $host"

  read  -n 1 -p "Press any key to continue"
fi

ansible-playbook -i $hostfile lotus_presealed_miner.yml                                                        \
                 -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
                 -e lotus_miner_import_wallet=true                                                             \
                 -e lotus_daemon_bootstrap=false                                                               \
                 -e lotus_service_state=stopped                                                                \
                 -e lotus_miner_reset="${RESET}"                                                               \
                 -e lotus_reset="${RESET}"                                                                     \
                 "$@"

PRESEALPATH=$(mktemp -d)

ansible -i $hostfile -b -m fetch -a "src=/tmp/presealed-metadata.json dest=${PRESEALPATH}" $host

pushd "$LOTUS_SRC"

SEEDPATH=$(mktemp -d)

./lotus-seed aggregate-manifests "${PRESEALPATH}/$host/tmp/presealed-metadata.json" > "${SEEDPATH}/miner.json"

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

read  -n 1 -p "Press any key to continue"

kill "$GDPID"

wait

cp "${GENPATH}/testnet.car" build/genesis/devnet.car

popd

../scripts/build_binaries.bash --src "$LOTUS_SRC"

ansible-playbook -i $hostfile lotus_presealed_miner.yml                                                        \
                 -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=false                                                               \
                 "$@"

sleep 30

ansible -i $hostfile -b -m shell -a 'lotus net id'                              $host

ansible -i $hostfile -b -m shell -a 'lotus chain list'                          $host
ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner-init'          $host

date -d @${TIMESTAMP} --utc +%FT%H:%M:%SZ

sleep 30

ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init || true' $host

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init || true' $host

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner'               $host
ansible -i $hostfile -b -m shell -a 'lotus chain list'                          $host

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'lotus chain list'                          $host

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
                 "$@"
