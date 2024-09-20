#!/usr/bin/env bash

set -xe

while [ "$1" != "" ]; do
    case $1 in
        -n | --network )        shift
                                network="$1"
                                ;;
        -s | --src )            shift
                                src="$1"
                                ;;
        -p | --preseal )        preseal=true
                                ;;
        -c | --create-cert )    cert=true
                                ;;
        -r | --reset )          reset=true
                                ;;
        --delay )               shift
                                delay="$1"
                                ;;
        --start-services )      shift
                                start_services="$1"
                                ;;
        --check )               check=true
                                ansible_args+=("--check")
                                ;;
        --verbose)              ansible_args+=("-v")
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
genesis_delay="${delay:-"600"}"
# genesis_timestamp="2021-06-19T00:00:00Z"
lotus_src="${src:-"${LOTUSROOT}"}"
start_services="${start_services:-"true"}"
check_mode="${check:-"false"}"

lotus-shed() {
    ${lotus_src}/lotus-shed "$@"
}

# gets a list of all the hostnames for the preminers
miners=( $(ansible-inventory -i $hostfile --list | jq -r '.preminer.children[] as $miner | .[$miner].children[0] as $group | .[$group].hosts[]') )

faucet_balance=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ faucet_initial_balance }}"' faucet | sed 's/.*=>//' | jq -r '.msg')
verifreg_rootkey=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ verifreg_rootkey }}"' faucet | sed 's/.*=>//' | jq -r '.msg')
miners_balance=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ miners_initial_balance }}"' preminer0 | sed 's/.*=>//' | jq -r '.msg')
network_flag=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ network_flag }}"' preminer0 | sed 's/.*=>//' | jq -r '.msg')
prepare_tmp=$(basename $(ansible -o -i $hostfile -b -m debug -a 'msg="{{ lotus_miner_data_root }}"' preminer0 | sed 's/.*=>//' | jq -r '.msg' ))

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

  # Update dnsaddr link to bootstrap peers
  ../scripts/update_bootstrap_dnsaddrs.bash "${network_name}" "${bootstrap_multiaddrs[@]}"

  pushd "$lotus_src"
    rm -f ./build/genesis/${network_flag}.car || true
    truncate -s 0 ./build/bootstrap/${network_flag}.pi

    for multiaddr in ${bootstrap_multiaddrs[@]}; do
      echo $multiaddr >> ./build/bootstrap/${network_flag}.pi
    done
  popd

  read -p "Press enter to continue"

fi

# gets the wallet address for the fountain, pcr servers and additional other balances
faucet_addr=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ lotus_fountain_address }}"' faucet | sed 's/.*=>//' | jq -r '.msg')
pcr_addr=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ lotus_wallet_address }}"' pcr | sed 's/.*=>//' | jq -r '.msg')
additional_accounts=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ additional_account_balance }}"' preminer0 | sed 's/.*=>//' | jq -r '.msg')

# runs all the roles
ansible-playbook -i $hostfile lotus_devnet_provision.yml                                           \
    -e lotus_binary_src="${LOTUSROOT}/lotus"                      \
    -e lotus_miner_binary_src="${LOTUSROOT}/lotus-miner"          \
    -e lotus_shed_binary_src="${LOTUSROOT}/lotus-shed"            \
    -e lotus_seed_binary_src="${LOTUSROOT}/lotus-seed"            \
    -e lotus_pcr_binary_src="${LOTUSROOT}/lotus-pcr"              \
    -e lotus_fountain_binary_src="${LOTUSROOT}/lotus-fountain"    \
    -e lotus_reset=yes -e lotus_miner_reset=yes -e lotus_pcr_reset=yes          \
    -e certbot_create_certificate=${create_certificate}                                            \
    --diff "${ansible_args[@]}"

if [ "$check_mode" = true ]; then
  # Nothing after this point will work when running a check
  exit 0
fi

preseal_metadata=$(mktemp -d)

# pulls down all the pre-sealed sectors from s3, hydrates the sectors, merges all the metadata, updates addresses everywhere
# and then downloads the final sector metadata for each preminer
ansible-playbook -i $hostfile lotus_devnet_prepare.yml -e local_preminer_metadata=${preseal_metadata} --diff "${ansible_args[@]}"

# Copy additional preseals to the temporary directory if they exist
additional_preseals_dir="ansible/files/additional_preseals"
if [ -d "${additional_preseals_dir}" ] && [ "$(ls -A ${additional_preseals_dir})" ]; then
  echo "Copying additional preseals from ${additional_preseals_dir} to ${preseal_metadata}"
  cp ${additional_preseals_dir}/pre-seal-*.json ${preseal_metadata}/
  echo "Copied $(ls -1 ${additional_preseals_dir}/pre-seal-*.json | wc -l) additional preseal files"
else
  echo "No additional preseals found in ${additional_preseals_dir} directory"
fi

genpath=$(mktemp -d)

if [ -f "multisig.csv" ]; then
  cp multisig.csv "${genpath}/multisig.csv"
fi

# build the genesis
pushd "$lotus_src"
  genesistmp=$(mktemp --suffix "-${network_name}")

  ./lotus-seed genesis new --network-name ${network_name} "${genpath}/genesis.json"
  ./lotus-seed genesis set-network-version "${genpath}/genesis.json"

  # Combine original miners and additional preseals
  all_miners=("${miners[@]}")
  for preseal_file in ${preseal_metadata}/pre-seal-*.json; do
      if [ -f "$preseal_file" ]; then
          miner_id=$(basename "$preseal_file" .json | sed 's/pre-seal-//')
          all_miners+=("$miner_id")
      fi
  done

  echo "All miners to be added: ${all_miners[@]}"

# ... (previous code remains unchanged)

  # Add all miners (original and additional) to genesis
  for miner in "${all_miners[@]}"; do
      preseal_file="${preseal_metadata}/${miner}/${prepare_tmp}/presealed-metadata.json"
      if [ ! -f "$preseal_file" ]; then
          preseal_file="${preseal_metadata}/pre-seal-${miner}.json"
      fi
      if [ -f "$preseal_file" ]; then
          echo "Adding miner $miner from $preseal_file"
          ./lotus-seed genesis add-miner "${genpath}/genesis.json" "$preseal_file"
          echo "Miner $miner added successfully"
      else
          echo "Warning: Preseal file not found for miner $miner"
      fi
  done

  echo "Debugging: Checking genesis file structure"
  jq '.' "${genpath}/genesis.json" | head -n 20

  echo "Debugging: Checking for top-level keys"
  jq 'keys' "${genpath}/genesis.json"

  echo "Miners in genesis before balance update:"
  jq '
    if has("Actors") then
      .Actors[] | select(.Code == "storageminer") | .ID
    elif has("Miners") then
      .Miners[] | .ID
    else
      "No miners found in expected structure"
    end
  ' "${genpath}/genesis.json"

  # Set balance for all miner accounts and miner owner accounts
  jq --arg MinerBalance "${miners_balance}" '
    if has("Actors") then
      .Accounts |= map(
        if .Type == "miner" or
           (.Type == "account" and (.Meta.Owner | test("^f[03]"))) then
          .Balance = $MinerBalance
        else
          .
        end
      )
    elif has("Miners") then
      .Miners |= map(
        .Balance = $MinerBalance
      ) |
      .Accounts |= map(
        if .Type == "account" and (.Meta.Owner | test("^f[03]")) then
          .Balance = $MinerBalance
        else
          .
        end
      )
    else
      .
    end
  ' < "${genpath}/genesis.json" > "${genesistmp}"
  mv "${genesistmp}" "${genpath}/genesis.json"

  # Print miner accounts and balances for verification
  echo "Miner accounts and balances after update:"
  jq '
    if has("Actors") then
      .Accounts[] | select(.Type == "miner") | {ID: .ID, Owner: .Meta.Owner, Balance: .Balance}
    elif has("Miners") then
      .Miners[] | {ID: .ID, Owner: .Owner, Balance: .Balance}
    else
      "No miners found in expected structure"
    end
  ' "${genpath}/genesis.json"

  echo "Miner owner accounts and balances after update:"
  jq '.Accounts[] | select(.Type == "account" and (.Meta.Owner | test("^f[03]"))) | {Owner: .Meta.Owner, Balance: .Balance}' "${genpath}/genesis.json"

# ... (rest of the script remains unchanged)

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

  ./lotus-seed genesis set-remainder --account ${faucet_addr} "${genpath}/genesis.json"

  jq --arg VerifyKey ${verifreg_rootkey} '.VerifregRootKey.Meta.Signers = [$VerifyKey] ' < "${genpath}/genesis.json" > ${genesistmp}
  mv ${genesistmp} "${genpath}/genesis.json"

  while read -r addr balance; do
    if [ -z "${addr}" ]; then
      continue
    fi

    jq --arg Owner ${addr} --arg Balance ${balance}  '.Accounts |= . + [{Type: "account", Balance: $Balance, Meta: {Owner: $Owner}}]' < "${genpath}/genesis.json" > ${genesistmp}
    mv ${genesistmp} "${genpath}/genesis.json"
  done <<<$(echo $additional_accounts | jq -rc '.[] | [.address, .balance] | @tsv' )

  ./lotus-seed genesis car --out="${genpath}/testnet.car" "${genpath}/genesis.json"

  cp "${genpath}/testnet.car" build/genesis/$network_flag.car

popd

# copy the genesis and start up all the services
ansible-playbook -i $hostfile lotus_devnet_start.yml                                                     \
    -e lotus_genesis_src="${LOTUSROOT}/build/genesis/$network_flag.car" \
    -e start_services="${start_services}" "${ansible_args[@]}"

set +x

echo "If everything is working correctly, miners will spend several minutes initializing."
echo "During the initialization phase, the systemd status for the lotus-miners will be $(tput smso)activating$(tput sgr0)."
echo "Once the initialization is complete, the status will transition to $(tput smso)active$(tput sgr0)."
echo "Wait for the transition, then take the faucet out of maintenance mode using the following line:"
echo
echo "    ansible -i $hostfile -b -m shell -a 'systemctl is-active lotus-miner' preminer"
echo
echo "    ansible -i $hostfile -b -m file -a 'state=link src=/etc/nginx/sites-available/faucet.conf dest=/etc/nginx/sites-enabled/50-faucet.conf' faucet"
echo "    ansible -i $hostfile -b -m systemd -a 'name=nginx state=reloaded' faucet"
echo
