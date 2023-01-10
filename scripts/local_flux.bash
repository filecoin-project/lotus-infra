#!/usr/bin/env bash

# This script will use k3d to start a new k8s cluster and will
# install *some* of the flux components. The resulting cluster
# will have the helm and kustomization controllers, but will not
# watch any remote git repositories.
#
# The kubernetes components installed by this script were created using
# If any errors are found, the script will exit with an error
#
# Optionally, you can specify kustomization build targets to install with the cluster.
# e.g. 
#			scripts/local_flux.bash kubernetes/gitops/dev/us-east-2/calibrationnet/tenant


CLUSTERNAME=flux-test-$RANDOM
CLUSTERCONTEXT=k3d-$CLUSTERNAME
WHEREAMI=$(dirname $0)
NAMESPACES=( ntwk-butterflynet ntwk-calibrationnet ntwk-mainnet )


echo ----------------------- CREATING CLUSTER
k3d cluster create "${CLUSTERNAME}" --wait
echo ----------------------- INSTALLING FLUX
flux install --context "${CLUSTERCONTEXT}"
echo ----------------------- INSTALLING FAKE CRDs
for i in "${WHEREAMI}"/test_crds/*.yaml 
do
	echo applying $i
	kubectl --context "${CLUSTERCONTEXT}" apply -f $i
done
echo ----------------------- SETTING UP NAMESPACES
for ns in ${NAMESPACES[@]}
do
	echo creating namespace $ns
	kubectl --context "${CLUSTERCONTEXT}" create namespace $ns
done

if [[ "$#" -gt 0 ]]
then
	echo ----------------------- Applying requested targets
	for target in "$@"
	do
		echo applying target $target
		kustomize build $target | kubectl --context "${CLUSTERCONTEXT}" apply --validate=ignore -f -
	done
fi

echo ----------------------- NOTES
echo you now hoave a flux-enabled cluster running locally.
echo this means, you can apply HelmReleases, HelmCharts, Kustomizations and they will be operated
echo by the same controllers in the weave gitops cluster.
echo
echo Once you are finished testing, you can delete this cluster like this...
echo k3d cluster delete $CLUSTERNAME
