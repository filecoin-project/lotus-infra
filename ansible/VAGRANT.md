Vagrant
=======

Install [vagrant `2.2.6`](https://releases.hashicorp.com/vagrant/2.2.6/)

```
vagrant plugin install vagrant-disksize
```

```
vagrant up --provision
```

To make working from a clean start easier take a snapshot of the machine after provisioning is complete.

```
vagrant snapshot save vagrant0 provisioned
```

Whenever you want to reset the machine, instead of destroying the machine, just restore it.

```
vagrant snapshot restore vagrant0 provisioned --no-provision
```

Presealer
---------

```
ansible-playbook -i vagrant_hosts.yml lotus_presealing.yml                            \
  -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed" \
  -e lotus_seed_reset_repo=yes                                                        \
  -e @vagrant_vars/lotus_seedm201s0.yml
```

Lotus Fullnode
--------------

### Deployment

```
ansible-playbook -i vagrant_hosts.yml lotus_daemon.yml                                \
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
ansible-playbook -i vagrant_hosts.yml lotus_daemon.yml                                \
  -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"           \
  -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed" \
  -e lotus_service_state=restarted
```

Lotus Miner
-----------

### Deployment

```
ansible-playbook -i vagrant_hosts.yml lotus_presealed_miner.yml                                 \
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
ansible-playbook -i vagrant_hosts.yml lotus_presealed_miner.yml                                 \
  -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                     \
  -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"           \
  -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-storage-miner" \
  -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"           \
```
