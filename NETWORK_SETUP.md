Note: This entire document needs to be updated to support the new network build flags for lotus

# Setting up a Filecoin network

Starting a Filecoin network using Lotus has a few steps which I will outline below, these steps will be the rather
verbose way to setup a network which tries to cover everything. Certain steps may not be required, but providing them all
gives the most flexibility and outlines the way we setup networks.

## Introduction

Starting a Filecoin network requires some special setup. To produce blocks on the Filecoin network, and therefore process
messages, a miner on the network must exist with power. For the start of the network this power is given to a miner during
the creation of the genesis. The power given to the miner isn't just a number, the miner is still required to
submit Window PoSt proofs as well as Winning PoSts for block production, there is no special casing for these miners.

## Basic steps

0. Preseal Sectors
0. Generate Genesis
0. Initialize Genesis Miner
0. Start Genesis Miner
0. Initialize all other miners
0. Start all other miners

Binaries required:
- jq
- lotus-shed
- lotus-seed
- lotus
- lotus-miner

# Simple Example

This example documents how to set up the Nerpa Network with a simple network configuration.

A minimally viable Lotus network is comprised of:
* Lotus "miner" with presealed sectors
* Lotus "bootstrap" node
* Genesis block
* Faucet

## Lotus Shed

The `lotus-shed` binary is where lotus keeps all of our tool programs.

### Generating bls keys for pre-sealing sectors

Creates a file called `bls-<address>.keyinfo` which will contain a keyinfo json object.

```
lotus-shed keyinfo new bls
```

### Generating libp2p ed25519 peer key

This will create a file called `libp2p-host-<address>.keyinfo` which will contain a keyinfo json object.

```
lotus-shed keyinfo new libp2p
```

### Importing keys to lotus repository

Note: Be sure to set the `LOTUS_PATH` before running the command if using a non standard location.

```
lotus-shed keyinfo import <filename>.keyinfo
```

### Downloading proof params

The lotus binary can also be used to download these, but to reduce the number of binaries that need be moved around
the command has also been added to `lotus-shed`.

```
lotus-shed fetch-params --proving-params 0
lotus-shed fetch-params --proving-params <sector-size>
```

## Lotus Seed

(The sectors can be special in one way though, because we can freely construct the genesis there is no pre-commit process).
This requires that sectors exist. The process of creating these sectors before the network is created is called pre-sealing,
and is done through the `lotus-seed` tool.

The `lotus-seed` binary is used to generate pre-sealed sectors for network bootstrap, as well as
constructing the network json configuration use to generate the genesis.

Note: As long as the replication construct of proofs do not change, keys stay secret, and the pre-sealed sectors
meet the minimum `ConsensusMinerMinMiners` value, pre-sealed sectors can be reused between networks.

### Pre-sealing sectors

For each miner wanted during the initial setup of a new network, sectors need to be pre-sealed.

```
lotus-seed pre-seal --miner-addr t01000 --key ./pre-seal-t01000.key --sector-size <sector-size> --num-sectors 4 --sector-offset 0
```


Note: Specifying a key is not required during lotus-seed (a key will be generated). When running parallel pre-sealing
using the `--sector-offset` flag keys should be generated beforehand and pass it into the `lotus-seed` process. However,
the sectors are not tied to any particilar key till the genesis is created. The key can be modified at anytime prior by
editing the `pre-seal-<miner>.json` files, or better yet, waiting till after running the `aggregate-manifests` command which
will produce a single file making it easier to edit the owner and worker keys.

```
cat pre-seal-t01000.json
{
  "t01000": {
    "ID": "t01000",
    "Owner": "t3qbp2kex6ljigeezzceeq4qoqyznshoekvfswpje4sqy36t6xbbb3fyzxlneftmy57bnj7kezc3ceqjm5mk5a",
    "Worker": "t3qbp2kex6ljigeezzceeq4qoqyznshoekvfswpje4sqy36t6xbbb3fyzxlneftmy57bnj7kezc3ceqjm5mk5a",
    "PeerId": "12D3KooWSsGT5Ky7EgAPcpKmGkKWq2fWSfR2CznSHrHLihiCQ1UR",
    "MarketBalance": "0",
    "PowerBalance": "0",
    "SectorSize": 2048,
    "Sectors": [...]
}
```

[TODO]: <> (There should be a command to change owner and work addresses at some point in the process, probably on the genesis network config?)

NOTE: pre-seal does not generate t_aux files which are required to exist along side every p_aux file. You will have to add these later

[TODO]: <> (There should be a command to do this or pre-seal should do it automatically.)

### Generate network configuration

Every network requires a genesis file to initialize from. This section will cover the generation of the configuration
which will later be used to generate the `genesis.car` file itself.

```
lotus-seed genesis new --network-name <network> /storage/<network>/genesis.json
```

#### Setting a network start time

If a genesis timestamp is not specified, the current time when the genesis is created will be used. A timestamp should
be defined to reduce the network mining race effect.

The `Timestamp` in the genesis configuration is a unix epoch.

[TODO]: <> (This should be a command in lotus-seed)

```
# GENESISDELAY is a time in seconds added to the current time to delay the network start by some amount of time
GENESISDELAY=3600

GENESISTMP=$(mktemp)
GENESISTIMESTAMP=$(date --utc +%FT%H:%M:00Z)
TIMESTAMP=$(echo $(date -d ${GENESISTIMESTAMP} +%s) + ${GENESISDELAY} | bc)

jq --arg Timestamp ${TIMESTAMP}                        \
   ' . + { Timestamp: $Timestamp|tonumber } '          \
   < "/storage/<network>/genesis.json" > ${GENESISTMP}
mv ${GENESISTMP} "/storage/<network>/genesis.json"
```

#### Adding miners

For each miner with pre-sealed sectors that should be included in the network will need to have their metadata file
added to the genesis.

```
lotus-seed genesis add-miner /storage/<network>/genesis.json /storage/<maddr>/pre-seal-<maddr>.json
```

### Generating the genesis.car

To generate the genesis car file, starting a lotus daemon is required. The `genesis.car` file will be created along side
the `genesis.json` file at `/storage/<network>/genesis.car` (this is a detail of this script).

```
GENESIS_JSON="/storage/<network>/genesis.json"
GENPATH=$(mktemp --suffix=genesis -d)

cp "${GENESIS_JSON}" "${GENPATH}/genesis.json"

lotus-seed genesis car              \
      --out="${GENPATH}/devnet.car" \
      "${GENPATH}/genesis.json"

cp ${GENPATH}/devnet.car $(dirname $GENESIS_JSON)/genesis.car
rm -rf ${GENPATH}
```

## Running bootstrap nodes

It's a good idea to run dedicated bootstrap nodes that are not the pre-sealed miners themselves. This is less important
on smaller networks, but on larger ones the bootstrap peers received so many connections that they cycle through peer
lists rather quickly which may affect block / message propagation to and from the miners.

Bootstrap nodes are just lotus daemons, ideally with a pre-generated libp2p host key so that redeployment is possible
without having to distribute new multiaddrs. Bootstrap nodes must all be publicly dial-able and have a static port, as
lotus by default uses a random port assigned by the kernel.

To compile bootstrap multiaddrs into the `lotus` binary, place the multiaddrs in `./build/bootstrap/bootstrappers.pi`.

Bootstrap nodes should also run the bootstrap profile by specifying it on the daemon commands.

```
lotus daemon --profile=bootstrapper
```

Optimally you may want to increase the `ConnMgrLow` and `ConnMgrHigh` values.

The `config.toml` should be located under `$LOTUS_PATH/config.toml`.

```
[Libp2p]
ListenAddresses = ["/ip4/0.0.0.0/tcp/1347"]
# ConnMgrLow =
# ConnMgrHigh =
```

Be sure to open any firewall rules. Here is an example ufw profile:

```
[Lotus Daemon]
title=Lotus Daemon
description=Lotus daemon firewall rules
ports=1347/tcp
```

## Initializing pre-sealed miners

Initializing requires running both the lotus daemon and a storage miner. Only a single miner is required to start
a network, but all pre-sealed miners for the network should be initialized together. It's not strictly required though.

There are no special flags we pass to the lotus daemon for these miners, besides the `--genesis` flag.

One miner must be marked the genesis miner.The genesis miner is the first miner to run and will mine the initial blocks
required for initialization of all other. Technically the other miners can be initialized after the genesis miner is
actually running the chain the chain is progressing. However, we always initialize them together and allow for a full
network initialization before actually running the miner.

For each pre-sealed set of sectors, a `--pre-sealed-sectors` flag must be passed. In this example we are only using one
directory.

Note: All pre-sealed miner daemons must be connected, this can be done by manually connecting them by running a
`lotus net connect` from all miners to the genesis miner's daemon. However, we recommend that you setup proper bootstrap
nodes and compile their addresses into the lotus daemon using the `build/bootstrap/bootstrappers.pi`.

After initialization the only thing requires is to start the storage miners themselves by running `lotus-storage-miner run`.

### Genesis miner

Note: There is nothing special about the `t01000` address here. It has just become practice to make it the genesis miner

```
lotus-storage-miner init --actor t01000                                             \
                         --sector-size <sector-size>                                \
                         --pre-sealed-metadata /storage/t01000/pre-seal-t01000.json \
                         --pre-sealed-sectors  /storage/t01000/pre-seal-0           \
                         --nosync --genesis-miner
```

# Advanced Usage

## Other network configuration

Not all network configuration is defined in the genesis itself. Some of these values are defined in varies policy files
of the specs-actors code itself.

Most notability are the supported sector sizes, minimum miner power, and block time. Currently these should be changed
by editing `build/params_testnet.go` of the lotus source code.


## Verified Registery

The Verified Registery can be interactived through the lotus-shed tool using signed messages. The address is set during
genesis creation. To be able to use the verified registery on a network, generate a key and replace the `Signers` array with
the address.

```
{
  "Accounts": [],
  "Miners": [],
  "NetworkName": "localnet-e415afe6-f7ed-402f-a6b9-480f44064561",
  "VerifregRootKey": {
    "Type": "multisig",
    "Balance": "0",
    "Meta": {
      "Signers": [
        "t1ceb34gnsc6qk5dt6n7xg6ycwzasjhbxm3iylkiy"
      ],
      "Threshold": 1,
      "VestingDuration": 0,
      "VestingStart": 0
    }
  }
}
```

## Adding additional accounts

Any additional accounts which should have preallocated funds in the network can be added by updating the `Accounts`
field.

You will want to keep this amount of funds preallocated through additional accounts to a minimum as all funds in these
accounts will count towards the circulating supply. Having a high ciruclating supply will result in high sector pledge
fees. For this reason, it's better to allocated all of the funds to a single actors, and set that actor to the account ID
of 90, which will not be counted towards the ciruclating supply. For public test networks, this account would be called the
faucet.

[TODO]: <> (This should be a command in lotus-seed to add accounts)
[TODO]: <> (There needs to a way to set the actor ID 90 account.)

```
# OWNER is a wallet address, use lotus-shed keyinfo --format '{{ .Address }}' <filename>.keyinfo
OWNER="<addr>"

# BALANCE is the amount of AttoFIL (10^-18 FIL) which will be preallocated to the account (wallet)
# 1 FIL == 1000000000000000000 AttoFIL
BALANCE=<balance>

GENESISTMP=$(mktemp)

jq --arg Owner ${OWNER} --arg Balance ${BALANCE}                                    \
   '.Accounts |= . + [{Type: "account", Balance: $Balance, Meta: {Owner: $Owner}}]' \
   < "/storage/<network>/genesis.json" > ${GENESISTMP}
mv ${GENESISTMP} "/storage/<network>/genesis.json"
```


## Other miners

Other miners have a similar initialization process, they just should not specify the `--genesis-miner` flag. This will
stop them from forking the network immediately by trying to mine their own chain.

```
lotus-storage-miner init --actor <maddr>                                              \
                         --sector-size <sector-size>                                  \
                         --pre-sealed-metadata /storage/<maddr>/pre-seal-<maddr>.json \
                         --pre-sealed-sectors  /storage/<maddr>/pre-seal-0            \
                         --pre-sealed-sectors  /storage/<maddr>/pre-seal-1            \
                         --pre-sealed-sectors  /storage/<maddr>/pre-seal-2            \
                         --nosync
```

## Pre-sealing Sectors in Parallel

The pre-sealing process can be run in parallel by suppling proper `--sector-offset` values. In a difference process the
output of this process can be merged together to create a single metadata file for the miner.

```
lotus-seed --sector-dir /storage/<maddr>/pre-seal-0 pre-seal ... --num-sectors 4 --sector-offset 0
lotus-seed --sector-dir /storage/<maddr>/pre-seal-1 pre-seal ... --num-sectors 4 --sector-offset 4
lotus-seed --sector-dir /storage/<maddr>/pre-seal-2 pre-seal ... --num-sectors 4 --sector-offset 8
```

### Merging pre-seal metadata of parallel pre-seals

If run a parallel pre-seal, sector metadata will need to be merged (`pre-seal-<maddr>.json`) together into a single
file. This file will then be used to construct the network configuration file.

```
lotus-seed aggregate-manifests                        \
    /storage/<maddr>/pre-seal-0/pre-seal-<maddr>.json \
    /storage/<maddr>/pre-seal-1/pre-seal-<maddr>.json \
    /storage/<maddr>/pre-seal-3/pre-seal-<maddr>.json > /storage/<maddr>/pre-seal-<maddr>.json
```

NOTE: Each of these lines updates some value, the first 3 lines (starting with the `$MinerId`) are probably not needed
```
/usr/local/bin/lotus-seed aggregate-manifests {{ lotus_miner_presealed_sectors | product([metadatafile]) | map('join', '/') | join(' ') }} \
| jq --arg Addr "{{ lotus_miner_wallet_address }}" --arg MinerId "{{ lotus_miner_addr }}" --arg VerifiedDeal "{{ lotus_miner_verified_deals | lower }}" '
    .[$MinerId].Owner = $Addr
  | .[$MinerId].Worker = $Addr
  | .[$MinerId].ID = $MinerId
  | .[$MinerId].Sectors[].Deal.Client = $Addr
  | .[$MinerId].Sectors[].Deal.VerifiedDeal = ($VerifiedDeal == "true")
  | .[$MinerId].Sectors[] |= (.Deal.Label = .CommR."/")
' > "{{ lotus_miner_presealed_metadata }}"
```


## Limits on number of sectors

There is an upper bound to the number of sectors a miner can have. This doesn't really affect 32/64 sector miners, but
the smaller test sectors have a limit of 2 sectors per partition and because lotus submits all parittions as a single
message this puts an upper bound of 5 partitions due to the proof size being 192 bytes and the maximum param size of
1024 bytes

https://github.com/filecoin-project/specs-actors/blob/v0.9.13/actors/builtin/sector.go#L83-L100
https://github.com/filecoin-project/specs-actors/blob/v3.0.0/actors/builtin/miner/policy.go#L96-L97

## Generating easily storable and reusable sectors

The following is a script which generates bucketed sectors which can easily be shared publicly and resused many times.
Sectors used in this way require that miner owner and worker keys are changed!

This script also truncates the sectors and requires that they are fixed after downloading. Bring the sectors back to their
correct size can be done using `truncate -s <SECTOR_SIZE> <path/to/sector>`.

```
#!/usr/bin/bash

set -xe

MINERS=(t01000 t01001 t01002 t01003 t01004 t01005)
PROOF_VERSION="v28"
SECTOR_SIZE="512MiB"
NUM_SECTORS=32
SECTOR_OFFSET=0
PATH_PREFIX="/storage/"
ROUNDS=$(seq 0 31)

export IPFS_GATEWAY="http://localhost:8080/ipfs/"
export FIL_PROOFS_USE_GPU_TREE_BUILDER=1
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
export RUST_LOG=info
export GOLOG_LOG_LEVEL=warn
export RUST_BACKTRACE=1

for MINER_ADDR in ${MINERS[@]}; do
  rm -rf "${PATH_PREFIX}/${PROOF_VERSION}/${SECTOR_SIZE}/${MINER_ADDR}"
  mkdir -p "${PATH_PREFIX}/${PROOF_VERSION}/${SECTOR_SIZE}/${MINER_ADDR}"

  for i in ${ROUNDS}; do
    SECTOR_OFFSET=$((i * NUM_SECTORS))
    SECTOR_OFFSET_VANITY=$(printf "%03d\n" ${SECTOR_OFFSET})

    mkdir -p "${PATH_PREFIX}/${PROOF_VERSION}/${SECTOR_SIZE}/${MINER_ADDR}/${SECTOR_OFFSET_VANITY}"

    lotus-seed --sector-dir "${PATH_PREFIX}/${PROOF_VERSION}/${SECTOR_SIZE}/${MINER_ADDR}/${SECTOR_OFFSET_VANITY}" \
      pre-seal                                                                                                     \
        --fake-sectors                                                                                             \
        --miner-addr ${MINER_ADDR}                                                                                 \
        --sector-size ${SECTOR_SIZE}                                                                               \
        --num-sectors ${NUM_SECTORS}                                                                               \
        --sector-offset ${SECTOR_OFFSET}                                                                           \
        2>&1 | tee -a ${PATH_PREFIX}/${PROOF_VERSION}/${SECTOR_SIZE}/${MINER_ADDR}/${SECTOR_OFFSET_VANITY}/pre-seal.log

    for i in $(ls "${PATH_PREFIX}/${PROOF_VERSION}/${SECTOR_SIZE}/${MINER_ADDR}/${SECTOR_OFFSET_VANITY}/sealed/"); do
      truncate -s 0 "${PATH_PREFIX}/${PROOF_VERSION}/${SECTOR_SIZE}/${MINER_ADDR}/${SECTOR_OFFSET_VANITY}/sealed/${i}"
      truncate -s 0 "${PATH_PREFIX}/${PROOF_VERSION}/${SECTOR_SIZE}/${MINER_ADDR}/${SECTOR_OFFSET_VANITY}/cache/${i}/t_aux"
    done

    tree -Fifs "${PATH_PREFIX}/${PROOF_VERSION}/${SECTOR_SIZE}/${MINER_ADDR}/${SECTOR_OFFSET_VANITY}"

  done
done
```

## Tipset Thresholds

Before lotus will start syncing a tipset, lotus requires that is has seen the tipset from a certain number of peers.
This value is defined by the build constant `BootstrapPeerThreshold`. When this value is set to any number greather
than one (1), starting a network runs into issues. This is because at the beggining of the network, there is only a
single peer that actually is producing blocks and sharing the tipset. Therefore no peers will try to sync the tipset.

To resolve this issue, the environment var `LOTUS_SYNC_BOOTSTRAP_PEERS` needs to be set to `1` on at least a number of peers
equal to the value of `BootstrapPeerThreshold`.

See https://github.com/filecoin-project/lotus/issues/5474 for more information.
