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
        -b | --build-flags )    shift
                                buildflags="$1"
                                ;;
        -- )                    shift; break
                                ;;
    esac
    shift
done

hostfile="inventories/${network}/hosts.yml"
network_name="${network%%.*}net"
build_flags="${buildflags:-""}"
lotus_src="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"


../scripts/build_binaries.bash --src "$lotus_src" ${build_flags} --network $network_flag --build-ffi

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
    -e lotus_reset=no -e lotus_miner_reset=no -e stats_reset=no -e lotus_pcr_reset=no              \
    -e chainwatch_db_reset=no -e chainwatch_reset=no                                               \
    -e certbot_create_certificate=${create_certificate}                                            \
    --diff -v
