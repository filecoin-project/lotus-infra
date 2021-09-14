#!/bin/bash
set -ex -o pipefail
AWS_PROFILE="${1:-}"
K8S_VERSION="${2}"
CLUSTER_NAME="${3}"
REGION="${4}"
DOMAIN_FILTER="${5}"
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

install_autoscaler() {
  helm repo add autoscaler https://kubernetes.github.io/autoscaler
  helm repo update
  helm upgrade --namespace=kube-system --install autoscaling \
    --set 'autoDiscovery.clusterName'="${CLUSTER_NAME}" \
    --set cloudProvider=aws \
    --set awsRegion="${REGION}" \
    --set 'extraArgs.balance-similar-node-groups'=true \
    --version "9.10.4" \
    autoscaler/cluster-autoscaler
}

install_external_dns() {
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  helm upgrade --namespace=kube-system --install public-dns \
    --set aws.region="${REGION}"  \
    --set aws.zoneType="public" \
    --set domainFilters="{${DOMAIN_FILTER}}" \
    --set logLevel="debug" \
    --set txtOwnerId="${CLUSTER_NAME}" \
    --version "5.1.3" \
    bitnami/external-dns
}

install_efs_csi() {
  kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.0"
}

install_ebs_csi() {
  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/alpha/?ref=4c58e81c4fd2bff9b6aab1537a67ca3933dd0350"
}

install_snapshot_crd() {
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/24a2aa84366248fbdfae9660dd3a768c57971605/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/24a2aa84366248fbdfae9660dd3a768c57971605/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/24a2aa84366248fbdfae9660dd3a768c57971605/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
}

install_calico() {
  kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/v1.7.2/config/v1.7/calico.yaml
}

install_storage_classes() {
  kubectl apply -f storage-ebs-csi-snapclass.yaml
  kubectl apply -f storage-ebs.yaml
}

check_kubectl_version
install_autoscaler
install_external_dns
install_efs_csi
install_ebs_csi
install_calico
install_snapshot_crd
