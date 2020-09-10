#!/bin/bash
set -ex -o pipefail
AWS_PROFILE="${1:-}"
K8S_VERSION="${2}"
AWS_PROFILE_FLAG=""
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
if [[ ! -z "${AWS_PROFILE}" ]]; then
  AWS_PROFILE_FLAG="--profile ${AWS_PROFILE}"
fi

check_kubectl_version() {
  local minimum="v${K8S_VERSION}.0"
  local current
  current="$(kubectl version --short --client | awk '{print $3}')"

  local lowest
  lowest="$(printf "%s\\n%s\\n", "${current}" "${minimum}" | sort -V | head -n1)"

  if [[ "${lowest}" != "${minimum}" ]]; then
    echo "kubectl ${minimum} or later required" >&2
    exit 1
  fi
}

install_external_dns() {
  kubectl apply -f /tmp/external-dns.yml
}

check_kubectl_version
install_external_dns
