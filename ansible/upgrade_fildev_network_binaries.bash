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
        --check )               ansible_args+=("--check")
                                ;;
        --verbose )             ansible_args+=("-v")
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
network_flag=$(ansible -o -i $hostfile -b -m debug -a 'msg="{{ network_flag }}"' preminer0 | sed 's/.*=>//' | jq -r '.msg')


../scripts/build_binaries.bash --src "$lotus_src" ${build_flags} --network $network_flag

# runs all the roles
ansible-playbook -i $hostfile lotus_update.yml \
    -e binary_src="$lotus_src"                 \
    --vault-password-file .vault_password      \
    --diff "${ansible_args[@]}"
