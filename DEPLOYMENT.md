Set `LOTUS_SRC` to the location of the lotus source code. The desired code should already
be checked out.

### Generate a new genesis

Files changed:
- `$LOTUS_SRC/build/genesis/devnet.car`
- `ansible/group_vars/genesis/wallet.vault.yml`

Running:
```
$ ./scripts/lotus-tools.bash new-network
```

After running, `devnet.car` should be commited to lotus

### Generate new peeykey for a host

Files changed:
- `ansible/host_vars/$host/libp2p.vault.yml`
- `$LOTUS_SRC/build/bootstrap/bootstrappers.pi`

Running:
```
$ ./scripts/lotus-tools.bash new-peerkey $host
```

After running, `bootstrappers.pi` should be commited to lotus

### Building new binaries

Files changed:
- `/tmp/lotus`
- `/tmp/lotus-storage-miner`
- `/tmp/lotus-fountain`

Running:
```
$ ./scripts/lotus-tools.bash build-binaries
```

# Deploying a new network

Note: You may want to generate new peerkeys for each bootstrapper

```
$ ./scripts/lotus-tools.bash new-network
$ ./scripts/lotus-tools.bash build-binaries
$ pushd terraform/testnet/
$ terraform12 destroy .
$ terraform12 plan -out testnet.tfplan -var 'lotus_copy_binary=true' -var 'lotus_miner_copy_binary=true' -var 'lotus_fountain_copy_binary=true'
$ terraform12 apply testnet.tfplan
```
