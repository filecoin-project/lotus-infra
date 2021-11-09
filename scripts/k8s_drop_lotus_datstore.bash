#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
PURP='\033[0;35m'
GRN='\033[0;32m'
NC='\033[0m'



usage() {
  echo "$(basename "$0") <namespace> <pod>"
  echo "this script will silence the LotusDaemonOutOfSync alert"
  echo "and set the magic reset file for lotus daemons deployed"
  echo "with easy-reset, and then delete the pod to initialize an"
  echo "import."
  exit 1
}

if [ "$#" -ne 2 ]; then
  usage
fi

namespace="$1"
pod="$2"
author="$USER"

alertmanager_pod=alertmanager-filecoin-base-kube-prometh-alertmanager-0

wait_for_input() {
  echo -en "${RED}"
  read -n 1 -s -r -p "Press any key to continue (ctrl-c to exit)"
  echo -en "${NC}"
  echo; echo;
}

get_info() {
  echo -e "${PURP}Gathering information for ${pod} in ${namespace}${NC}"
  echo -e "current-context ${GRN}$(kubectl config current-context)${NC}"
  echo
  kubectl --namespace "${namespace}" get pod "${pod}"
  kubectl --namespace "${namespace}" exec -it "${pod}" --container daemon -- bash -c 'df -h $LOTUS_PATH/datastore/'
}

silence_sync_alert() {
  echo -e "${PURP}Silencing LotusDaemonOutOfSync for ${pod} in ${namespace}${NC}"
  kubectl --namespace kube-system exec -it ${alertmanager_pod} --container alertmanager -- \
    amtool --alertmanager.url=/      \
    silence add LotusDaemonOutOfSync \
      namespace="${namespace}"       \
      pod="${pod}"                   \
    --comment "resetting datastore" --duration=2h --author="$author"
}

reset_pod_datastore() {
  echo -e "${PURP}Resetting datastore ${pod} in ${namespace}${NC}"
  kubectl --namespace "${namespace}" exec -it "${pod}" --container daemon -- bash -c 'touch $LOTUS_PATH/datastore/_reset'
  kubectl --namespace "${namespace}" delete pod "${pod}"
}

get_info
wait_for_input
silence_sync_alert
reset_pod_datastore
