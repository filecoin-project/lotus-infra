# Bare Metal Kubernetes

## Requirements
* Terraform 0.12
* Ansible 2.8

## Terraform
Found in `terraform/storage-miner-k8s-dfw2`

## Kubernetes Deploy Instructions

1. Edit `main.tf` - ensure `ceph_mon` and `ceph_osd` packet_devices are set to `network_type: hybrid` if starting a new cluster. If they are in `layer2-individual` mode they will not reachable, but this is necessary when Ceph is competely setup. In `layer2-individual` servers will not be reachable by public IP
1. In `main.tf` also comment out `packet_port_vlan_attachment`s `ceph_mon_2` and `ceph_osd_2`
1. Run `terraform plan` and `terraform apply`
1. Change directories to `../ansible`
1. Fill out public IPs in `inventories/storage-miner-k8s-dfw2/hosts.yaml` (@TODO automate this or add DNS records in terraform). Static VLAN IPs can remain the same. If you're adding more hosts, assign new IPs
1. To fill out `mdmadm_arrays` and `swap_device` variables, run `ansible -i inventories/storage-miner-k8s-dfw2/hosts.yml -m shell -a 'lsblk' seal_worker`. Device names are not deterministic, so you need to manually fill this out for now :(
1. Run `ansible-playbook -i inventories/storage-miner-k8s-dfw2 storage_miner_k8s_vlan.yml` to configure vlan interfaces. Kubernetes will use this network for any internode communication.
1. Run `ansible-playbook -i inventories/storage-miner-k8s-dfw2 storage_miner_k8s.yml` to install docker, kubernetes, and associated tooling
1. Run `ansible-playbook -i inventories/storage-miner-k8s-dfw2 storage_miner_k8s_gpu.yml` to install nvidia drivers on host and in docker
1. Run `ansible-playbook -i inventories/storage-miner-k8s-dfw2 storage_miner_k8s_block_devices.yml` to format and mount block devices and create swap
1. SSH to `k8s_master` server
1. Run `kubectl get nodes` to verify all servers have joined k8s cluster
1. Run `helm ls` to ensure helm is installed
1. Go back to terraform and change `network_type: layer2-individual` and uncomment vlan2 attachments
1. Run `terraform apply`
1. Back to ansible again. You'll need to change the inventory file and change hostname to vlan1 private ip of each Ceph host. We'll access the servers via SSH on these IPs
1. Configure SSH to tunnel through k8s master to reach Ceph servers. A sample file in `~/.ssh/config`:
```
Host 192.168.1.*
  ProxyCommand ssh -W %h:%p root@<K8S-MASTER-PUBLIC-IP>
  IdentityFile ~/.ssh/id_rsa

Host 139.178.82.15
  User root
  IdentityFile ~/.ssh/id_rsa
  ControlMaster auto
  ControlPath ~/.ssh/ansible-%r@%h:%p
  ControlPersist 5m
```
1. Configure ansible to use this configuration by editing `~/.ansible.cfg`
```
[ssh_connection]
ssh_args = -F ./ssh.cfg -o ControlMaster=auto -o ControlPersist=30m
control_path = ~/.ssh/ansible-%%r@%%h:%%p
```
1. Run `ansible-playbook -i inventories/storage-miner-k8s-dfw2 storage_miner_k8s_vlan2.yml` to configure vlan2 interfaces. This is the Ceph replication network
1. Run `ansible-playbook -i inventories/storage-miner-k8s-dfw2 storage_miner_k8s_nat.yml` to configure a NAT gateway to be used later by Ceph servers
1. SSH back in `k8s_master`
1. Create namespace `kubectl apply -f namespaces.yaml`
1. Label and taint nodes `./label-taints.sh`

## Install Rook Ceph
1. SSH in `k8s_master`
1. Change directories to `rook-ceph`
1. Install rook `./install-rook.sh`
1. Install ceph `kubectl apply -f ceph-cluster.yaml`
