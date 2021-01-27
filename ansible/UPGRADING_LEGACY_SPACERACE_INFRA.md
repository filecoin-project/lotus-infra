# Upgrading lotus and tools on legacy spacerace infra

The spacerace was transfered over into mainnet infra and as such still need to be maintained and updated
periodicially with releases of the lotus software.

## Updating binaries

1. Clone down the release that is to be updated

```
$ git clone https://github.com/filecoin-project/lotus.git --branch <branch/tag> --single-branch /tmp/<branch/tag>
```

2. Run a build of the code and required binaries to update

```
$ ../scripts/build_binaries.bash --src /tmp/<branch/tag> --network <network> -- lotus lotus-miner lotus-seed lotus-shed lotus-stats
```

3. Check update

You will want to look over the plan and ensure only the binaries are being updated and no other configuration is changing.
If you see something you are not sure of reach out to someone.

```
$ ansible-playbook -i $hostfile lotus_update.yml --diff -e lotus_import_jwt=false -e lotus_import_wallet=false -e binary_src=/tmp/<branch/tag> --check
```

4. Upload new binaries

```
$ ansible-playbook -i $hostfile lotus_update.yml --diff -e lotus_import_jwt=false -e lotus_import_wallet=false -e binary_src=/tmp/<branch/tag>
```

5. Restart the daemon

```
$ ansible -i $hostfile -b -m shell -a 'lotus daemon stop' lotus_daemon
```
