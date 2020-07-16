Vagrant
=======

Install [vagrant `2.2.9`](https://releases.hashicorp.com/vagrant/2.2.9/)
Image: ubuntu/bionic64
 - https://ipfs.io/ipfs/QmQvvzXTUydatqHaFs15rSyowocsfTWZUWszE4nNEBqFBv/ubuntu-18.04-server-cloudimg-amd64-vagrant.box
 - http://cloud-images.ubuntu.com/releases/bionic/release-20200129.1/ubuntu-18.04-server-cloudimg-amd64-vagrant.box

```
ipfs get -o . QmQvvzXTUydatqHaFs15rSyowocsfTWZUWszE4nNEBqFBv/ubuntu-18.04-server-cloudimg-amd64-vagrant.box
vagrant box add --name "ubuntu/bionic64" ubuntu-18.04-server-cloudimg-amd64-vagrant.box
```

```
vagrant plugin install vagrant-disksize
```

```
vagrant up --provision
```

To make working from a clean start easier take a snapshot of the machine after provisioning is complete.

```
for i in $(seq 0 3); do vagrant snapshot save "vagrant$i" provisioned; done
```

Whenever you want to reset the machine, instead of destroying the machine, just restore it.

```
for in in $(seq 0 3); do vagrant snapshot restore "vagrant$i" provisioned --no-provision; done
```

Building Binaries
-----------------

```
../scripts/build_binaries.bash --debug
```

*assumes your code is under `$GOPATH/src/github.com/filecoin-project/lotus`*

Presealer
---------

```
ansible-playbook -i inventories/vagrant/hosts.yml lotus_presealing.yml                \
  -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed" \
  -e lotus_seed_reset=yes
```

Lotus Fullnode
--------------

### Deployment

```
ansible-playbook -i inventories/vagrant/hosts.yml lotus_daemon.yml                    \
  -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"           \
  -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed" \
  -e lotus_service_state=[started|stopped]
  [ -e lotus_daemon_bootstrap=false ]
  [ -e lotus_import_peerkey=true ]
  [ -e lotus_import_wallet=true ]
```

*`lotus_import_peerkey` and `lotus_import_wallet` will need corresponding `lotus_libp2p_keyinfo`
and `lotus_wallet_keyinfo` in their host_vars*

### Binary Update

```
ansible-playbook -i inventories/vagrant/hosts.yml lotus_daemon.yml                    \
  -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"           \
  -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed" \
  -e lotus_service_state=restarted
```

Lotus Miner
-----------

### Deployment

```
ansible-playbook -i inventories/vagrant/hosts.yml lotus_presealed_miner.yml                     \
  -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
  -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"           \
  -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
  -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
  -e lotus_service_state=[started|stopped]
  [ -e lotus_daemon_bootstrap=false ]
  [ -e lotus_import_peerkey=true ]
```

*`lotus_import_peerkey` and `lotus_import_wallet` will need corresponding `lotus_libp2p_keyinfo`
and `lotus_wallet_keyinfo` in their host_vars*

### Binary Update

```
ansible-playbook -i inventories/vagrant/hosts.yml lotus_presealed_miner.yml                     \
  -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
  -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"           \
  -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
  -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
```
