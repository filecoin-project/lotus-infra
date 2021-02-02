#!/usr/bin/env bash

# Wraps build_containers.bash and minikube commandlines.
# Pass minikube commands first, then build_containers arguments after "--"
# For example, for native compilation with GPUs, try the following:
#
#                       (minikube options)           || (build_containers options)
# ./build_minikube.bash --driver kvm2 --kvm-gpu=true -- --native

declare -a MINIKUBE_OPTS

while [ "$1" != "" ]; do
	case $1 in
		-- ) shift
			   break
				 ;;
		 * )  MINIKUBE_OPTS+=($1)
			   shift
			   ;;
	esac
done

# Minikube options stored in the MINIKUBE_OPTS array
# build_containers arguments are stored in the shifted arguments array $@

# Start kubernetes
minikube start "${MINIKUBE_OPTS[@]}"

# Build containers
DEV_DOCKER_TAG=localdev
./build_containers.bash "${@}" --docker-tag $DEV_DOCKER_TAG

# Add local images to kubernetes cache
minikube cache add lotus-miner:"$DEV_DOCKER_TAG"
minikube cache add lotus-worker:"$DEV_DOCKER_TAG"
minikube cache add lotus:"$DEV_DOCKER_TAG"

# Enable a few addons
minikube addons enable dashboard
minikube addons enable ingress
minikube addons enable logviewer
minikube addons enable metrics-server
minikube addons enable volumesnapshots

echo Added these images to local kubernetes dev environment.
echo Try them out! 
echo e.g. `kubectl run  --image lotus:localdev my_k8s_daemon -- daemon`
minikube cache list
