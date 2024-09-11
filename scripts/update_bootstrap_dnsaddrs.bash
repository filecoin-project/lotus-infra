#!/bin/bash

# Ensure correct usage: at least 2 arguments (network-name and one or more bootstrap multiaddr)
[[ $# -lt 2 ]] && { echo "Usage: $0 <network-name> <multiaddr>..."; exit 1; }

NETWORK_NAME=${1}

# Extract the domain name
DOMAIN_NAME=$(
  case ${NETWORK_NAME} in
  butterflynet) printf 'butterfly.fildev.network' ;;
  *) exit 1 ;;
  esac
) || {
  echo "❌ Unknown network: ${NETWORK_NAME}"
  exit 1
}
echo "✅ Using domain name: ${DOMAIN_NAME}"
shift 1

# Find the Route53 hosted zone ID from domain name.
LIST_OUTPUT=$(aws route53 list-hosted-zones-by-name --dns-name "${DOMAIN_NAME}" --query 'HostedZones[0].Id' --output text  2>&1) || {
  echo "❌ Hosted zone not found for '${NETWORK_NAME}' network with domain '${DOMAIN_NAME}':"
  echo "${LIST_OUTPUT}"
  exit 1
}
HOSTED_ZONE_ID=${LIST_OUTPUT#/hostedzone/}
echo "✅ Found hosted zone ID for domain: ${HOSTED_ZONE_ID}"

# Create an array of ResourceRecords, each prefixed with "dnsaddr=" and remove tailing comma.
# See addressing spec:
#  - https://github.com/libp2p/specs/blob/master/addressing/README.md#dnsaddr-links
RESOURCE_RECORDS=$(printf '{"Value": "\\"dnsaddr=%s\\""},' "$@")
RESOURCE_RECORDS=${RESOURCE_RECORDS%,}

# Submit the change batch to upsert the TXT record and capture the change ID.
CHANGE_OUTPUT=$(aws route53 change-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID}" \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "_dnsaddr.bootstrap.'"${DOMAIN_NAME}"'",
        "Type": "TXT",
        "TTL": 300,
        "ResourceRecords": ['"${RESOURCE_RECORDS}"']
      }
    }]
  }' --query 'ChangeInfo.Id' --output text 2>&1) || {
  echo '❌ Failed to submit TXT record changes:'
  echo "${CHANGE_OUTPUT}"
  exit 1
}

echo '✅ Change submitted successfully. Waiting for the changes to propagate...'
aws route53 wait resource-record-sets-changed --id "${CHANGE_OUTPUT}" || {
  echo '❌ Failed to propagate the TXT record.'
  exit 1
}

echo "✅ Bootstrap dnsaddr for ${NETWORK_NAME} network propagated successfully:"
echo "     /dnsaddr/bootstrap.${DOMAIN_NAME}"
