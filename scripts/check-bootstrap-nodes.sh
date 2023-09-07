#!/bin/bash
set -eou pipefail

COLOR_REST="$(tput sgr0)"
COLOR_GREEN="$(tput setaf 2)"
COLOR_RED="$(tput setaf 1)"

function info() {
  echo "${COLOR_GREEN}$1${COLOR_REST}"
}

function error() {
  echo "${COLOR_RED}$1${COLOR_REST}"
}

function handle_trap() {
  interrupted=true
}
trap handle_trap SIGINT SIGTERM;

if ! which lotus 2>&1 > /dev/null; then
  error "lotus not found. You must have lotus available on your path to use this command"
  exit 1
fi

if ! lotus net id; then
  error "Lotus must be connected to the network for this command to function"
  exit 1
fi

BS_PEER="$(curl -s https://raw.githubusercontent.com/filecoin-project/lotus/master/build/bootstrap/mainnet.pi)"
interrupted=false

set +e
declare -a failed_peers
declare -a working_peers
for peer in $BS_PEER; do
  info "Checking peer $peer"
  lotus net connect $peer
  rc=$?
  if [[ $rc != 0 ]]; then
    error "Failed to connect to peer $peer"
    failed_peers+=($peer)
  else
    working_peers+=($peer)
  fi

  if [[ $interrupted == true ]]; then
    info "Interrupted by user"
    break;
  fi
done

set +u  # So that empty array doesn't error
echo ""
if [[ ${#working_peers[@]} -ne 0 ]]; then
  info "[Summary]: Successfully connected to the following peers:"
  for peer in "${working_peers[@]}"; do
    echo $peer;
  done
fi

echo ""
if [[ ${#failed_peers[@]} -ne 0 ]]; then
  info "[Summary]: We were unable to connect to the following peers:"
  for peer in "${failed_peers[@]}"; do
    echo $peer;
  done
else
  info "[Summary]: All peers were reachable"
fi
