#!/bin/bash
set -ex -o pipefail
AWS_PROFILE="${1:-}"
K8S_VERSION="${2}"
CLUSTER_NAME="${3}"
REGION="${4}"
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
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm upgrade --namespace=kube-system --install public-dns \
    --set aws.region="${REGION}"  \
    --set aws.zoneType="public" \
    --set domainFilters="{filops.net}" \
    --set logLevel="debug" \
    --set txtOwnerId="${CLUSTER_NAME}" \
    bitnami/external-dns
}

install_efs_csi() {
  kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.0"
}

install_ebs_csi() {
  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
}

install_calico() {
  kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/v1.7.2/config/v1.7/calico.yaml
}

check_kubectl_version
install_external_dns
install_efs_csi
install_ebs_csi
install_calico
