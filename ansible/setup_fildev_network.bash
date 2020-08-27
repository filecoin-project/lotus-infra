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
        -ss | --sentinel-src )   shift
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
#genesis_timestamp="2020-08-24T22:00:00Z"
lotus_src="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"
sentinel_src="${ssrc:-"$GOPATH/src/github.com/filecoin-project/sentinel"}"
verifreg_rootkey="t1meqrx2ijvgrdquybafmlwgszpmc34b3kg3nohvy"

# gets a list of all the hostnames for the preminers
miners=( $(ansible-inventory -i $hostfile --list | jq -r '.preminer.children[] as $miner | .[$miner].children[0] as $group | .[$group].hosts[]') )

faucet_balance=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ faucet_initial_balance }}"' faucet | sed 's/.*=>//' | jq -r '.msg')
miners_balance=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ miners_initial_balance }}"' preminer0 | sed 's/.*=>//' | jq -r '.msg')

if [ "$generate_new_keys" = true ]; then
  # get a list of all hosts which have a lotus_libp2p_address defined somewhere in their group / hosts vars.
  libp2p_hosts=( $(ansible-inventory -i $hostfile --list | jq -r '._meta.hostvars | to_entries[] | select( .value.lotus_libp2p_address?) | .key ') )
  jwt_hosts=( $(ansible-inventory -i $hostfile --list | jq -r '._meta.hostvars | to_entries[] | select( .value.lotus_import_jwt?) | .key ') )

  for host in ${jwt_hosts[@]}; do
    lotus-shed jwt new ${host}
    jwt_keyinfo=$(cat jwt-${host}.jwts)
    jwt_token=$(cat jwt-${host}.token)
    rm "jwt-${host}.jwts"
    rm "jwt-${host}.token"

    cat > "$(dirname $hostfile)/host_vars/$host/lotus_jwt.vault.yml" <<EOF
vault_lotus_jwt_keyinfo: $jwt_keyinfo
vault_lotus_jwt_token: $jwt_token
EOF
  done

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

    secp256k1_address=$(lotus-shed keyinfo new secp256k1)
    secp256k1_keyinfo=$(cat secp256k1-${secp256k1_address}.keyinfo)
    rm "secp256k1-${secp256k1_address}.keyinfo"

    cat > "$(dirname $hostfile)/group_vars/faucet/lotus_daemon.vault.yml" <<EOF
vault_lotus_wallet_keyinfo: $secp256k1_keyinfo
vault_lotus_wallet_address: $secp256k1_address
EOF

    secp256k1_address=$(lotus-shed keyinfo new secp256k1)
    secp256k1_keyinfo=$(cat secp256k1-${secp256k1_address}.keyinfo)
    rm "secp256k1-${secp256k1_address}.keyinfo"

    cat > "$(dirname $hostfile)/group_vars/pcr/lotus_daemon.vault.yml" <<EOF
vault_lotus_wallet_keyinfo: $secp256k1_keyinfo
vault_lotus_wallet_address: $secp256k1_address
EOF


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

# gets the wallet address for the fountain, pcr servers and additional other balances
faucet_addr=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ lotus_fountain_address }}"' faucet | sed 's/.*=>//' | jq -r '.msg')
pcr_addr=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ lotus_wallet_address }}"' pcr | sed 's/.*=>//' | jq -r '.msg')
additional_accounts=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ additional_account_balance }}"' preminer0 | sed 's/.*=>//' | jq -r '.msg')

#ssh ubuntu@192.168.1.240 bash -c "'
#git -C /home/ubuntu/src/github.com/filecoin-project/lotus fetch black
#git -C /home/ubuntu/src/github.com/filecoin-project/lotus checkout v0.5.0
#pushd /home/ubuntu/src/github.com/filecoin-project/lotus-infra
#./scripts/build_binaries.bash -f -s /home/ubuntu/src/github.com/filecoin-project/lotus
#popd
#'"

#pushd $lotus_src/intel
#rm -rf lotus lotus-miner lotus-shed lotus-seed
#scp ubuntu@192.168.1.240:/home/ubuntu/src/github.com/filecoin-project/lotus/lotus .
#scp ubuntu@192.168.1.240:/home/ubuntu/src/github.com/filecoin-project/lotus/lotus-miner .
#scp ubuntu@192.168.1.240:/home/ubuntu/src/github.com/filecoin-project/lotus/lotus-seed .
#scp ubuntu@192.168.1.240:/home/ubuntu/src/github.com/filecoin-project/lotus/lotus-shed .
#popd

../scripts/build_binaries.bash -s "$lotus_src" ${build_flags}
../scripts/build_binaries.bash -s "$sentinel_src" -- telegraf

# runs all the roles
ansible-playbook -i $hostfile lotus_devnet_provision.yml                                           \
    -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                      \
    -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-miner"          \
    -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"            \
    -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"            \
    -e lotus_pcr_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-pcr"              \
    -e lotus_fountain_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-fountain"    \
    -e stats_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-stats"                \
    -e chainwatch_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-chainwatch"      \
    -e sentinel_telegraf_binary_src="$GOPATH/src/github.com/filecoin-project/sentinel/build/telegraf"\
    -e lotus_reset=yes -e lotus_miner_reset=yes -e stats_reset=yes -e lotus_pcr_reset=yes          \
    -e chainwatch_db_reset=no -e chainwatch_reset=yes                                              \
    -e certbot_create_certificate=${create_certificate}                                            \
    --diff

# runs all the roles
# ansible-playbook -i $hostfile lotus_devnet_provision2.yml                                           \
#    -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/intel/lotus"                      \
#    -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/intel/lotus-miner"          \
#    -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/intel/lotus-shed"            \
#    -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/intel/lotus-seed"            \
#    -e sentinel_telegraf_binary_src="$GOPATH/src/github.com/filecoin-project/sentinel/build/telegraf"\
#    -e lotus_reset=yes -e lotus_miner_reset=yes -e stats_reset=yes -e lotus_pcr_reset=yes          \
#    -e chainwatch_db_reset=no -e chainwatch_reset=yes                                              \
#    -e certbot_create_certificate=${create_certificate}                                            \
#    --diff


preseal_metadata=$(mktemp -d)

# pulls down all the pre-sealed sectors from s3, hydrates the sectors, merges all the metadata, updates addresses everywhere
# and then downloads the final sector metadata for each preminer
ansible-playbook -i $hostfile lotus_devnet_prepare.yml -e local_preminer_metadata=${preseal_metadata}


genpath=$(mktemp -d)

if [ -f "multisig.csv" ]; then
  cp multisig.csv "${genpath}/multisig.csv"
fi

# build the genesis
pushd "$lotus_src"
  genesistmp=$(mktemp --suffix "-${network_name}")

  ./lotus-seed genesis new --network-name ${network_name} "${genpath}/genesis.json"

  for m in "${miners[@]}"; do
    ./lotus-seed genesis add-miner "${genpath}/genesis.json" "${preseal_metadata}/${m}/tmp/presealed-metadata.json"
  done

  jq --arg MinerBalance ${miners_balance}  '.Accounts[].Balance = $MinerBalance ' < "${genpath}/genesis.json" > ${genesistmp}
  mv ${genesistmp} "${genpath}/genesis.json"

  if [ -f "${genpath}/multisig.csv" ]; then
    ./lotus-seed genesis add-msigs "${genpath}/genesis.json" "${genpath}/multisig.csv"
  fi

  if [ -z "${genesis_timestamp}" ]; then
    timestamp=$(echo $(date -d $(date --utc +%FT%H:%M:00Z) +%s) + ${genesis_delay} | bc)
  else
    timestamp=$(date -d "${genesis_timestamp}" +%s)
  fi


  jq --arg Timestamp ${timestamp} ' . + { Timestamp: $Timestamp|tonumber } ' < "${genpath}/genesis.json" > ${genesistmp}
  mv ${genesistmp} "${genpath}/genesis.json"

  jq --arg Owner ${faucet_addr} --arg Balance ${faucet_balance}  '.Accounts |= . + [{Type: "account", Balance: $Balance, Meta: {Owner: $Owner}}]' < "${genpath}/genesis.json" > ${genesistmp}
  mv ${genesistmp} "${genpath}/genesis.json"

  # Provide the PCR service the same balance as the faucet
  jq --arg Owner ${pcr_addr} --arg Balance ${faucet_balance}  '.Accounts |= . + [{Type: "account", Balance: $Balance, Meta: {Owner: $Owner}}]' < "${genpath}/genesis.json" > ${genesistmp}
  mv ${genesistmp} "${genpath}/genesis.json"

  while read -r addr balance; do
    if [ -z "${addr}" ]; then
      continue
    fi

    jq --arg Owner ${addr} --arg Balance ${balance}  '.Accounts |= . + [{Type: "account", Balance: $Balance, Meta: {Owner: $Owner}}]' < "${genpath}/genesis.json" > ${genesistmp}
    mv ${genesistmp} "${genpath}/genesis.json"
  done <<<$(echo $additional_accounts | jq -rc '.[] | [.address, .balance] | @tsv' )

  jq --arg VerifyKey ${verifreg_rootkey} '.VerifregRootKey.Meta.Signers = [$VerifyKey] ' < "${genpath}/genesis.json" > ${genesistmp}
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

echo "Monitor the initialization process on all miners (until a bug is fixed you will need to watch the /var/log/lotus-miner.log)"
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
