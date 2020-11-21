#!/bin/bash
helm repo add rook-release https://charts.rook.io/release
helm install --namespace rook-ceph --values rook-ceph-operator-values.yaml storage rook-release/rook-ceph --version "1.3.7"
