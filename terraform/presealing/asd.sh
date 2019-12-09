#!/usr/bin/env bash

set -o pipefail

[[ "$TRACE" ]] && set -x

#terraform12 show -json > state.json

#for item in $(jq -rc '.values.root_module.child_modules[].resources[] | select ( .type == "aws_ebs_volume" and .name == "merge" ) | { name: .values.tags.Name, id: .values.id } ' < state.json); do
for item in $(cat list.ldjson); do
  echo $item
  name=$(echo $item | jq -r '.name')
  id=$(echo $item | jq -r '.id')
  aws --profile="filecoin" --region="us-east-1" ec2 create-snapshot             \
    --volume-id "$id"                                                           \
    --description "$name backup"                                                \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=$name}]"  \
    | tee -a snapshot_info.ldjson
done
