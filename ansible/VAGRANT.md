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
  -e lotus_seed_copy_binary=true                                                      \
  -e lotus_seed_reset_repo=yes                                                        \
  -e @vagrant_vars/lotus_seedm201s0.yml
```
