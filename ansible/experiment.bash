#!/usr/bin/bash

hostfile="inventories/calibration.fildev.network/hosts.yml"

build_flags="${buildflags:-"-f"}"
lotus_src="${src:-"$GOPATH/src/github.com/filecoin-project/lotus"}"
sentinel_src="${ssrc:-"$GOPATH/src/github.com/filecoin-project/sentinel"}"

# ../scripts/build_binaries.bash -s "$lotus_src" ${build_flags}
# ../scripts/build_binaries.bash -s "$sentinel_src" -- telegraf



# Setup the experiment
ansible-playbook -i $hostfile experiment.yml \
    -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                      \
    -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-miner"          \
    -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"            \
    -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"            \
    -e lotus_fountain_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-fountain"    \
    -e stats_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-stats"                \
    -e telegraf_binary_src="$GOPATH/src/github.com/filecoin-project/sentinel/build/telegraf"       \
    -e lotus_reset=yes -e lotus_miner_reset=yes -e stats_reset=no \



