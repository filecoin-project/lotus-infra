This is a collection of how to run different commands across different groups of hosts

Available group selectors (see testnet_hosts.yml for source)
- all
- miners
- bootstrappers
- fountain
- stats
- aws
- packet

-----------------------

### Running shell commands as lotus user

```
$ ansible -b --become-user lotus -m shell -a 'lotus net id'
```

#### Examples

Inspect last three blocks of chain across all hosts
```
$ ansible -b --become-user lotus -m shell -a 'lotus chain list --count 3' all
```

Listing balance of miner wallets
```
$ ansible -b --become-user lotus -m shell -a 'lotus wallet list | xargs -L1 lotus wallet balance' miners
```

### Running arbitrary commands as root

Note: `miner` group logs in as `ubuntu` be default, this is diferent from all packet machines
which will login as `root` by default. The `ubuntu` user will not have access to any lotus
repos, so you will either need to become `root` or `lotus`.

```
$ ansible -b -m shell -a 'systemctl status lotus-daemon' all
```
