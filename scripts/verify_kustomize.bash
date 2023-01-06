#!/usr/bin/env bash

# This script finds all kustomization.yaml files and runs `kustomize build`
# If any errors are found, the script will exit with an error


declare -a BADBUILDS
ERRFILE=$(mktemp)

for k in $(find . -name kustomization.yaml); do
	DIR=$(dirname "${k}")
	kustomize build "${DIR}" 2>>"${ERRFILE}" >/dev/null
	if [[ $? != 0 ]]; then
		BADBUILDS+=("${DIR}")
	fi
done

if [[ "${#BADBUILDS[@]}" > 0 ]]; then
	echo 🚨❌❌🚨 Uh oh! some of the kustomizations are invalid. 🚨❌❌🚨
	echo Please investigate the following kustomizations:
	echo
	for bad in "${BADBUILDS[@]}"; do
		echo "${bad}"
	done
	echo ----------------------------------------------------------------
	cat "${ERRFILE}"
	exit 1
else
	echo no bad kustomizations were identified. 
fi
