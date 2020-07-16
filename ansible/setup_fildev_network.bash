#!/usr/bin/bash

set -xe

while [ "$1" != "" ]; do
    case $1 in
        -n | --network )        shift
                                network="$1"
                                ;;
        -s | --src )            shift
                                src="$1"
                                ;;
        -ss | --sentinal-src )   shift
                                ssrc="$1"
                                ;;
        -p | --preseal )        preseal=true
                                ;;
        -c | --create-cert )    cert=true
                                ;;
        -b | --build-flags )    shift
                                buildflags="$1"
                                ;;
        -r | --reset )          reset=true
                                ;;
        --delay )               shift
                                delay="$1"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        -- )                    shift; break
                                ;;
    esac
    shift
done

hostfile="inventories/${network}/hosts.yml"
generate_new_keys="${reset:-"false"}"
network_name="${network%%.*}net"
create_certificate="${cert:-"false"}"
build_flags="${buildflags:-"-f"}"
genesis_delay="${delay:-"600"}"
lotus_src="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"
sentinal_src="${ssrc:-"$GOPATH/src/github.com/filecoin-project/sentinal"}"

# gets a list of all the hostnames for the preminers
miners=( $(ansible-inventory -i $hostfile --list | jq -r '.preminer.children[] as $miner | .[$miner].children[0] as $group | .[$group].hosts[]') )

# gets the wallet address for the fountain
faucet_addr=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ lotus_fountain_address }}"' faucet | sed 's/.*=>//' | jq -r '.msg')

faucet_balance=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ faucet_initial_balance }}"' faucet | sed 's/.*=>//' | jq -r '.msg')

if [ "$generate_new_keys" = true ]; then
  # get a list of all hosts which have a lotus_libp2p_address defined somewhere in their group / hosts vars.
  libp2p_hosts=( $(ansible-inventory -i $hostfile --list | jq -r '._meta.hostvars | to_entries[] | select( .value.lotus_libp2p_address?) | .key ') )

  for bootstrapper in ${libp2p_hosts[@]}; do
    p2p_address=$(lotus-shed keyinfo new libp2p-host)
    p2p_keyinfo=$(cat libp2p-host-${p2p_address}.keyinfo)
    rm "libp2p-host-${p2p_address}.keyinfo"

    cat > "$(dirname $hostfile)/host_vars/$bootstrapper/libp2p.vault.yml" <<EOF
libp2p_keyinfo: $p2p_keyinfo
libp2p_address: $p2p_address
EOF
  done

  # gets a list of the actuall miner ids, not the hostnames
  miner_ids=( $(ansible-inventory -i $hostfile --list | jq -r '.preminer.children[]') )
  for miner in ${miner_ids[@]}; do
    bls_address=$(lotus-shed keyinfo new bls)
    bls_keyinfo=$(cat bls-${bls_address}.keyinfo)
    rm "bls-${bls_address}.keyinfo"

    cat > "$(dirname $hostfile)/group_vars/$miner/lotus_miner.vault.yml" <<EOF
vault_lotus_miner_wallet_keyinfo: $bls_keyinfo
vault_lotus_miner_wallet_address: $bls_address
EOF
  done


  # generate multiaddrs for the bootstrap peers
  bootstrap_multiaddrs=( $(ansible -o -i $hostfile -b -m debug -a 'msg="/dns4/{{ ansible_host }}/tcp/{{ lotus_libp2p_port }}/p2p/{{ lotus_libp2p_address }}"' bootstrap | sed 's/.* =>//' | jq -r '.msg') )

  pushd "$lotus_src"
    rm -f ./build/genesis/devnet.car || true
    truncate -s 0 ./build/bootstrap/bootstrappers.pi

    for multiaddr in ${bootstrap_multiaddrs[@]}; do
      echo $multiaddr >> ./build/bootstrap/bootstrappers.pi
    done
  popd

  read -p "Press enter to continue"

fi

../scripts/build_binaries.bash -s "$lotus_src" ${build_flags}
../scripts/build_binaries.bash -s "$sentinal_src" ${build_flags}

# runs all the roles
ansible-playbook -i $hostfile lotus_devnet_provision.yml                                           \
    -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                      \
    -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner"  \
    -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"            \
    -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"            \
    -e lotus_fountain_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/fountain"          \
    -e stats_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/stats"                      \
    -e chainwatch_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/chainwatch"            \
    -e lotus_reset=yes -e lotus_miner_reset=yes -e stats_reset=yes                                 \
    -e chainwatch_db_reset=yes -e chainwatch_reset=yes                                             \
    -e certbot_create_certificate=${create_certificate}                                            \
    --diff

preseal_metadata=$(mktemp -d)

# pulls down all the pre-sealed sectors from s3, hydrates the sectors, merges all the metadata, updates addresses everywhere
# and then downloads the final sector metadata for each preminer
ansible-playbook -i $hostfile lotus_devnet_prepare.yml -e local_preminer_metadata=${preseal_metadata}

# build the genesis
pushd "$lotus_src"

  genpath=$(mktemp -d)
  ./lotus-seed genesis new --network-name ${netowrk_name} "${genpath}/genesis.json"

  for m in "${miners[@]}"; do
    ./lotus-seed genesis add-miner "${genpath}/genesis.json" "${preseal_metadata}/${m}/tmp/presealed-metadata.json"
  done

  timestamp=$(echo $(date -d $(date --utc +%FT%H:%M:00Z) +%s) + ${genesis_delay} | bc)

  genesistmp=$(mktemp)

  jq --arg Timestamp ${timestamp} ' . + { Timestamp: $Timestamp|tonumber } ' < "${genpath}/genesis.json" > ${genesistmp}
  mv ${genesistmp} "${genpath}/genesis.json"

  jq --arg Owner ${faucet_addr} --arg Balance ${faucet_balance}  '.Accounts |= . + [{Type: "account", Balance: $Balance, Meta: {Owner: $Owner}}]' < "${genpath}/genesis.json" > ${genesistmp}
  mv ${genesistmp} "${genpath}/genesis.json"

  ./lotus --repo="${genpath}" daemon --api 0 --lotus-make-genesis="${genpath}/testnet.car" --genesis-template="${genpath}/genesis.json" --bootstrap=false &
  ldpid=$!

  while true; do
    if [ ! -f "${genpath}/testnet.car" ]; then
      sleep 5
    else
      break
    fi
  done

  sleep 30

  kill "$ldpid"

  wait

  cp "${genpath}/testnet.car" build/genesis/devnet.car

popd

# copy the genesis and start up all the services
ansible-playbook -i $hostfile lotus_devnet_start.yml                                            \
    -e lotus_genesis_src="$GOPATH/src/github.com/filecoin-project/lotus/build/genesis/devnet.car"

set +x

echo "Monitor the initialization process on all miners"
echo ""
echo "    ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner-init' preminer"
echo ""
echo "When all have finished the process will exit with a message about 'run lotus-storage-miner run'"
echo ""
echo "    ansible -i $hostfile -b -m shell -a 'systemctl status lotus-miner-init' preminer"
echo ""
echo "Start the 'lotus-miner' serivce on all preminers"
echo ""
echo "    ansible -i $hostfile -b -m shell -a 'systemctl start lotus-miner' preminer"
echo ""
echo "Remove the faucet from maintenance mode, and reload nginx to pick up the new config"
echo ""
echo "    ansible -i $hostfile -b -m file -a 'state=link src=/etc/nginx/sites-available/faucet.conf dest=/etc/nginx/sites-enabled/50-faucet.conf' faucet"
echo "    ansible -i $hostfile -b -m systemd -a 'name=nginx state=reloaded' faucet"
echo ""
