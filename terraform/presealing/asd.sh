#!/usr/bin/env bash

set -eo pipefail

[[ "$TRACE" ]] && set -x

terraform12 show -json > state.json

for item in $(jq -c '.values.root_module.resources[] | select ( .type == "aws_ebs_volume" ) | { name: .values.tags.Name, id: .values.id } ' < state.json); do
  name=$(echo $item | jq -r '.name')
  id=$(echo $item | jq -r '.id')

  aws --profile="filecoin" --region="us-east-1" ec2 create-snapshot             \
    --volume-id "$id"                                                           \
    --description "$name backup"                                                \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=$name}]"  \
    | tee -a snapshot_info.ldjson
done
