#!/usr/bin/bash

hostfile="inventories/butterfly.fildev.network/hosts.yml"

build_flags="${buildflags:-"-f"}"
lotus_src="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"
sentinel_src="${ssrc:-"$GOPATH/src/github.com/filecoin-project/sentinel"}"

#../scripts/build_binaries.bash -s "$lotus_src" ${build_flags}
#../scripts/build_binaries.bash -s "$sentinel_src" -- telegraf



# Setup the experiment
ansible-playbook -i $hostfile experiment.yml \
    -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                      \
    -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-miner"          \
    -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"            \
    -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"            \
    -e lotus_fountain_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-fountain"    \
    -e stats_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-stats"                \
    -e telegraf_binary_src="$GOPATH/src/github.com/filecoin-project/sentinel/build/telegraf"       \
    -e lotus_reset=yes -e lotus_miner_reset=yes -e stats_reset=yes                                 \



# failed: [toolshed-1.butterfly.fildev.network] (item=lotus_path) => {"ansible_loop_var": "item", "changed": false, "item": "lotus_path", "msg": "Variable 'lotus_path' is not defined"}
# failed: [toolshed-1.butterfly.fildev.network] (item=lotus_golog_file) => {"ansible_loop_var": "item", "changed": false, "item": "lotus_golog_file", "msg": "Variable 'lotus_golog_file' is not defined"}
# failed: [toolshed-1.butterfly.fildev.network] (item=lotus_proof_params_path) => {"ansible_loop_var": "item", "changed": false, "item": "lotus_proof_params_path", "msg": "Variable 'lotus_proof_params_path' is not defined"}
# failed: [toolshed-1.butterfly.fildev.network] (item=lotus_libp2p_port) => {"ansible_loop_var": "item", "changed": false, "item": "lotus_libp2p_port", "msg": "Variable 'lotus_libp2p_port' is not defined"}


