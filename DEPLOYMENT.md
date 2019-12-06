Set `LOTUS_SRC` to the location of the lotus source code. The desired code should already
be checked out.

### Generate a new genesis

Files changed:
- `$LOTUS_SRC/build/genesis/devnet.car`
- `ansible/host_vars/lotus-genesis.fil-test.net/wallet.vault.yml`
- `/tmp/lotus-genesis-sectors.tar.gz`

Running:
```
$ ./scripts/lotus-tools.bash new-genesis
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

# Testnet Network Deployment

0. Set `$LOTUS_SRC`
   ```
   $ export LOTUS_SRC=$(mktemp -d)
   ```
0. Set `$TESTNET_BRANCH`
   This may not be `master`, lotus team will let us know
   ```
   $ export TESTNET_BRANCH=master
   ```
1. Checkout lotus src
   ```
   $ git clone --branch $TESTNET_BRANCH git@github.com/filecoin-project/lotus.git $LOTUS_SRC
   ```
1. Truncate bootstrapper list
   ```
   $ truncate --size 0 $LOTUS_SRC/build/bootstrap/bootstrappers.pi
   ```
1. Generate new bootstrapper peerkeys
   ```
   $ ./scripts/lotus-tools.bash new-peerkey lotus-bootstrap-0.yyz.fil-test.net
   $ ./scripts/lotus-tools.bash new-peerkey lotus-bootstrap-1.yyz.fil-test.net
   $ ./scripts/lotus-tools.bash new-peerkey lotus-bootstrap-0.hkg.fil-test.net
   $ ./scripts/lotus-tools.bash new-peerkey lotus-bootstrap-1.hkg.fil-test.net
   ```
1. Generate genesis and presealed sectors and build release binaries for deployment
   ```
   $ ./scripts/lotus-tools.bash new-genesis
   $ ./scripts/lotus-tools.bash build-binaries
   ```
1. Plan terraform
   ```
   $ pushd terraform/testnet/
   $ terraform12 plan -out testnet.tfplan -var 'lotus_copy_binary=true' -var 'lotus_miner_copy_binary=true' -var 'lotus_fountain_copy_binary=true' -var 'lotus_reset=yes' -var 'certbot_create_certificate=true'
   $ terraform12 apply testnet.tfplan
   $ popd
   ```
1. Commit lotus arifacts
   ```
   $ pushd $LOTUS_SRC
   $ git add build/bootstrap/bootstrappers.pi
   $ git add build/genesis/devnet.car`
   $ popd
   ```
