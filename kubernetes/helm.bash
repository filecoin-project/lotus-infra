#!/usr/bin/env bash

set -euo pipefail

# requirements: yq jq helm-diff
# yq is a small tool to convert yaml to json and then invoke jq, output is in json

cluster=""
diff="false"

print_help() {
  echo "helm.bash --cluster <cluster-name> -- <additioanl-helm-args>"
  exit 1
}

while [ "${1-}" != "" ]; do
  case $1 in
    --cluster )       shift
                      cluster="$1"
                      ;;
    --diff )          diff="true"
                      ;;
    -h | --help )     shift
                      print_help
                      ;;
    -- )              shift
                      break
                      ;;
  esac
  shift
done

if [ -z "$cluster" ]; then
  print_help
  exit 1
fi

for deployment in $(yq -c ' .deployments[] ' ./$cluster/helm/config.yaml); do
  read -r values <<<$(echo "$deployment" | jq -c -r '.values')
  read -r chart <<<$(echo "$deployment" | jq -c -r '.chart')
  read -r namespace <<<$(echo "$deployment" | jq -c -r '.namespace')

  for value in $(echo "$values" | jq -c -r '.[]'); do
    if [ ! -f "./$cluster/helm/$namespace/$chart/$value.yaml" ]; then
      echo "Values file does not exist:" "./$cluster/helm/$namespace/$chart/$value.yaml"
      exit 1
    fi
  done
done

cmd="upgrade --install"
if [ "$diff" == "true" ]; then
  cmd="diff upgrade"
fi

for deployment in $(yq -c ' .deployments[] ' ./$cluster/helm/config.yaml); do
  read -r chart <<<$(echo "$deployment" | jq -c -r '.chart')
  read -r version <<<$(echo "$deployment" | jq -c -r '.version')
  read -r namespace <<<$(echo "$deployment" | jq -c -r '.namespace')
  read -r name <<<$(echo "$deployment" | jq -c -r '.name')
  read -r values <<<$(echo "$deployment" | jq -c -r '.values')

  valueFlags=()
  for value in $(echo "$values" | jq -c -r '.[]'); do
    if [ ! -f "./$cluster/helm/$namespace/$chart/$value.yaml" ]; then
      echo "Values file does not exist:" "./$cluster/helm/$namespace/$chart/$value.yaml"
      exit 1
    fi
    valueFlags+=(--values "./$cluster/helm/$namespace/$chart/$value.yaml")
  done

  echo helm --namespace $namespace $cmd $name $chart --version $version "${valueFlags[@]}" $@
done
