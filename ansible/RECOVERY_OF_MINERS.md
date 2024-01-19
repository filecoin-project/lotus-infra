# How to recover preminers

This is not an exact step-by-step but more of a guideline on how to recover miners, this
document has been written after recovering the preminers on calibration due to a terraform
issue that resulted in the miner boxes being destroyed.

If this operation is successful this could later be used to transfer miners.

These steps were created by selecting a subset of the `setup_fildev_network.bash` script.
0. Install gpu drivers
```
ansible-playbook -i $hostfile preminer.yml
```
1. Checkout the correct lotus code
2. Build the lotus binaries

```
scripts/build_binaries.bash --src $HOME/src/github.com/filecoin-project/lotus --network calibnet
```
3. Run the provision script on the preminers
```
ansible-playbook -i $hostfile lotus_devnet_provision.yml                                           \
    -e lotus_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus"                      \
    -e lotus_miner_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-miner"          \
    -e lotus_shed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-shed"            \
    -e lotus_seed_binary_src="$GOPATH/src/github.com/filecoin-project/lotus/lotus-seed"            \
    --limit preminer
```
4. Run the prepare playbook on the preminers
```
ansible-playbook -i $hostfile lotus_devnet_prepare.yml -e local_preminer_metadata=/tmp/foobar --limit preminer
```
5. Copy the genesis to the miners
```
ansible-playbook -i $hostfile lotus_devnet_start.yml                                                \
    -e lotus_genesis_src="$GOPATH/src/github.com/filecoin-project/lotus/build/genesis/calibnet.car" \
    -e start_services="false" --limit preminer
```
6. Start various services
We don't start this with the previous step because we want to make sure the nodes are synced first,
this is important because preminer-0 by default has a `nosync` flag set on the miner, so it could start
to fork from genessi.
```
ansible -i $hostfile -b -m service -a 'name=lotus-daemon state=started' preminer
```
7. Wait for the daemons to be sync, this might take a while depending on the age of the network
```
ansible -i $hostfile -b -m shell -a 'lotus sync status' preminer
```
8. Start the miners
```
ansible -i $hostfile -b -m service -a 'name=lotus-miner state=started' preminer
```
