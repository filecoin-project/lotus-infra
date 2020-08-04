#!/bin/bash
kubectl taint nodes storage-miner-ceph-osd-0 storage-miner-ceph-osd-1 storage-miner-ceph-osd-2 ceph=osd:NoSchedule
kubectl taint nodes storage-miner-ceph-mon-0 storage-miner-ceph-mon-1 storage-miner-ceph-mon-2 ceph=mon:NoSchedule
kubectl label nodes storage-miner-ceph-osd-0 storage-miner-ceph-osd-1 storage-miner-ceph-osd-2 ceph=osd
kubectl label nodes storage-miner-ceph-mon-0 storage-miner-ceph-mon-1 storage-miner-ceph-mon-2 ceph=mon
kubectl taint nodes storage-miner-0 role=lotus-miner:NoSchedule
kubectl taint nodes storage-miner-precomm1-worker-0 storage-miner-precomm1-worker-1 role=lotus-precomm1-worker:NoSchedule
kubectl taint nodes storage-miner-precomm2-comm-worker-0 role=lotus-precomm2-comm-worker:NoSchedule
kubectl label nodes storage-miner-0 role=lotus-miner
kubectl label nodes storage-miner-precomm1-worker-0 storage-miner-precomm1-worker-1 role=lotus-precomm1-worker
kubectl label nodes storage-miner-precomm2-comm-worker-0 role=lotus-precomm2-comm-worker
kubectl taint nodes storage-miner-monitoring-0 monitoring=true:NoSchedule
kubectl label nodes storage-miner-monitoring-0 monitoring=true
kubectl taint nodes storage-miner-generic-0 nat-gateway=true:NoSchedule
