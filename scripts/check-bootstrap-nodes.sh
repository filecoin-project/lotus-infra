#!/bin/bash
set -eo pipefail

usage() {
  set +x
  echo "usage: build_containers.bash
    [--output        ] output formatting: plain (DEFAULT), json"
}

while [ "$1" != "" ]; do
    case $1 in
        --output )              shift
                                if [ "${1}" = "json" ]; then
                                  output="json"
                                else
                                  output="plain"
                                fi
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

set -u
COLOR_REST="$(tput sgr0)"
COLOR_GREEN="$(tput setaf 2)"
COLOR_RED="$(tput setaf 1)"

function info() {
  local msg="$1"
  if [ "$output" = "json" ]; then
    local time="$(date -Iseconds)"
    echo $(jq -nr --arg time "$time" --arg msg "$msg" '.time = $time| .msg = $msg| .level = "info"')
  else
    echo "${COLOR_GREEN}$msg${COLOR_REST}"
  fi
}

function error() {
  local msg="$1"
  if [ "$output" = "json" ]; then
    local time="$(date -Iseconds)"
    echo $(jq -nr --arg time "$time" --arg msg "$msg" '.time = $time| .msg = $msg| .level = "error"') >&2
  else
    echo "${COLOR_RED}$msg${COLOR_REST}"
  fi
}

function check_jq() {
  if ! which jq 2>&1 > /dev/null; then
    error "jq not found. You must have jq available when output option is set 'json'"
  fi
}
function format_result_line() {
  local peer="$1"
  local result="$2"
  local line=""
  if [ "$output" = "json" ]; then
    local time="$(date -Iseconds)"
    line=$(jq -nr --arg peer "$peer" --arg result "$result" --arg time "$time" '.time = $time| .result = {"type": "connection", "peer": $peer, "success": $result}'
)
  else
    line="$peer"
  fi
  echo "$line"
}
function handle_trap() {
  interrupted=true
}
trap handle_trap SIGINT SIGTERM;

if ! which lotus 2>&1 > /dev/null; then
  error "lotus not found. You must have lotus available on your path to use this command"
  exit 1
fi

if [ i"$output" = "json" ]; then
  check_jq
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
  if [ $output = "plain" ]; then
    info "[Summary]: Successfully connected to the following peers:"
  fi
  for peer in "${working_peers[@]}"; do
    format_result_line "$peer" "true"
  done
fi

echo ""
if [[ ${#failed_peers[@]} -ne 0 ]]; then
  if [ "$output" = "plain" ]; then
    info "[Summary]: We were unable to connect to the following peers:"
  fi
  for peer in "${failed_peers[@]}"; do
    format_result_line "$peer" "false"
  done
else
  if [ "$output" = "plain" ]; then
    info "[Summary]: All peers were reachable"
  fi
fi

