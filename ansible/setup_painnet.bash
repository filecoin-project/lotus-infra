#!/usr/bin/env bash

set -xe

genesis="t01000.miner.fil-test.net"
miners=("t01000.miner.fil-test.net" "t01001.miner.fil-test.net" "t01002.miner.fil-test.net" "t01003.miner.fil-test.net")
hostfile="inventories/testnet/hosts.yml"
faucetaddr="t1wn6ayeny3hh425lcatf5i7a3pvjwwncri67moni"
faucetbalance="10000000000000000000000000"

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
NETWORKNAME="testnet"

../scripts/build_binaries.bash -f --src "$LOTUS_SRC"

ansible-playbook -i $hostfile lotus_presealed_miner.yml                                                        \
                 -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
                 -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"           \
                 -e lotus_miner_import_wallet=true                                                             \
                 -e lotus_daemon_bootstrap=false                                                               \
                 -e lotus_service_state=stopped                                                                \
                 -e lotus_miner_reset="${RESET}"                                                               \
                 -e lotus_reset="${RESET}"                                                                     \
                 "$@"

PRESEALPATH=$(mktemp -d)

ansible -i $hostfile -b -m fetch -a "src=/tmp/presealed-metadata.json dest=${PRESEALPATH}" presealed_miners

pushd "$LOTUS_SRC"

GENPATH=$(mktemp -d)

./lotus-seed genesis new "${GENPATH}/genesis.json"

for m in "${miners[@]}"; do
  ./lotus-seed genesis add-miner "${GENPATH}/genesis.json" "${PRESEALPATH}/${m}/tmp/presealed-metadata.json"
done

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

../scripts/build_binaries.bash -f --src "$LOTUS_SRC"

ansible-playbook -i $hostfile lotus_presealed_miner.yml                                                        \
                 -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
                 -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
                 -e lotus_service_state=started                                                                \
                 -e lotus_daemon_bootstrap=false                                                               \
                 "$@"

sleep 30


peerid=$(ansible -i $hostfile -b -m shell -a 'lotus net id' $genesis | grep 12D3Koo)
ansible -i $hostfile -b -m shell -a "lotus net connect /dns4/${genesis}/tcp/1347/p2p/${peerid}" presealed_miners || true

sleep 30

ansible -i $hostfile -b -m shell -a 'lotus chain list'                          presealed_miners
ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner-init'          presealed_miners

date -d @${TIMESTAMP} --utc +%FT%H:%M:%SZ

sleep 30

ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init || true' presealed_miners

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init || true' presealed_miners

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner'               $genesis
ansible -i $hostfile -b -m shell -a 'lotus chain list'                          $genesis

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'lotus chain list'                          $genesis

read  -n 1 -p "Press any key to continue"

ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner'               presealed_miners
