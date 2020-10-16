#!/usr/bin/env bash

set -euo pipefail

# requirements: yq jq
# yq is a small tool to convert yaml to json and then invoke jq, output is in json

for deployment in $(yq -c ' .deployments[] ' ./config.yaml); do
  read -r values <<<$(echo "$deployment" | jq -c -r '.values')
  read -r chart <<<$(echo "$deployment" | jq -c -r '.chart')
  read -r namespace <<<$(echo "$deployment" | jq -c -r '.namespace')

  for value in $(echo "$values" | jq -c -r '.[]'); do
    if [ ! -f "./$namespace/$chart/$value.yaml" ]; then
      echo "Values file does not exist:" "./$namespace/$chart/$value.yaml"
      exit 1
    fi
  done
done

for deployment in $(yq -c ' .deployments[] ' ./config.yaml); do
  read -r chart <<<$(echo "$deployment" | jq -c -r '.chart')
  read -r version <<<$(echo "$deployment" | jq -c -r '.version')
  read -r namespace <<<$(echo "$deployment" | jq -c -r '.namespace')
  read -r name <<<$(echo "$deployment" | jq -c -r '.name')
  read -r values <<<$(echo "$deployment" | jq -c -r '.values')

  valueFlags=()
  for value in $(echo "$values" | jq -c -r '.[]'); do
    if [ ! -f "./$namespace/$chart/$value.yaml" ]; then
      echo "Values file does not exist:" "./$namespace/$chart/$value.yaml"
      exit 1
    fi
    valueFlags+=(--values "./$namespace/$chart/$value.yaml")
  done

  echo helm --namespace $namespace upgrade --install $name $chart --version $version "${valueFlags[@]}" $@
done
