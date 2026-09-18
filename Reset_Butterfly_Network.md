# Reset Butterfly Network

## Summary

This runbook is intended for maintainers of the Lotus-Infra repo and provides instructions on how to reset the Butterfly network infrastructure. It assumes that properly configured branches or tags have been made with the correct network parameters in Lotus. This runbook does not cover how to configure the Butterfly network.

## General Information

- A list of hosts for the Butterfly network infrastructure and their roles can be found [here](https://github.com/filecoin-project/lotus-infra/blob/main/ansible/inventories/butterfly.fildev.network/hosts.yml).
- The instances running the Butterfly network infrastructure are in the FilOz AWS account (us-east-1). FilOz members can get credentials to log in and confirm that these are running in their 1Password account.
- The hosts are normally torn down after an upgrade's Butterfly testing is complete to save cost (see [Tearing down the Butterfly network](#tearing-down-the-butterfly-network)). Do not assume they exist; check first (see below).
- A reset on hosts that have been provisioned before takes roughly 45 minutes of workflow time, most of it building Lotus.
- A reset on freshly created hosts takes closer to two hours. Each preminer downloads about 24 GB of proof parameters for 512MiB sectors (the SnapDeals `empty-sector-update` file alone is 21.7 GB). Where they come from is decided by [go-paramfetch](https://github.com/filecoin-project/go-paramfetch), which Lotus uses for `fetch-params`; the inventory's `lotus_ipfs_gateway` variable overrides its default. The parameters live in `/var/tmp/filecoin-proof-parameters` on each host and are lost when the hosts are destroyed, so this cost is paid once per teardown. The workflow job timeout is set with this in mind; a reset on fresh hosts used to be killed at the previous 60 minute limit before the download finished.
- Only preminers (the `lotus_miner` inventory group) get these params from ansible during a reset. If you stand up a miner anywhere else (e.g. for manual upgrade testing on scratch-0 or toolshed-1, see "Manual upgrade testing" below), prefer copying the missing files directly from a preminer that already has them over re-downloading from the public gateway: it's a same-region, same-VPC transfer (measured at 150-250 MB/s between preminer-0 and scratch-0, vs. the public gateway being slow enough that it drove the 180-minute reset timeout above) and it's read-only on the source host. `scripts/butterfly_manual_testing.bash fetch-params` automates this (throwaway IP-restricted SSH key, diff + rsync, then revokes the key), falling back to the public gateway if the source host is unreachable.

## Prerequisites

### Confirm the hosts exist, and recreate them if not

The EC2 hosts are managed by terraform in `terraform/testnets/deployments/butterfly_network`. If the hosts were destroyed after the previous upgrade, the reset workflow fails with every host `UNREACHABLE` (SSH connection timed out) and DNS still points at the old IPs.

To check, and to recreate them if needed:

```bash
cd terraform/testnets/deployments/butterfly_network
# Use the terraform version in .tool-versions (asdf, or install it directly).
# Use AWS credentials for the FilOz account (e.g. AWS_PROFILE=filoz).
terraform init
terraform plan     # "0 to add" means the hosts exist; "8 to add" means they need creating
terraform apply
```

Creating the hosts takes under a minute. DNS records under `butterfly.fildev.network` are updated by the same apply. The state lives in the `filoz-terraform-state` S3 bucket, so anyone with FilOz AWS credentials sees the same view.

`terraform plan` only tells you whether the instances exist in state, not whether they are running. An instance that was stopped from the AWS console still shows as "0 to add". So also confirm they are running and reachable:

```bash
aws ec2 describe-instances --region us-east-1 \
  --filters 'Name=tag:Name,Values=preminer-*,bootstrap-*,toolshed-*,scratch-*' \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,State.Name]' --output text

cd ansible
ansible -i inventories/butterfly.fildev.network/hosts.yml all -m ping   # needs your SSH key on the hosts
```

Start any stopped instances with `aws ec2 start-instances --instance-ids <id>`; their public IPs change on start, so run `terraform apply` afterwards to update DNS. If an instance is missing or broken, `terraform apply` replaces it.

When recreating, consider bumping the `ami` in `main.tf` to a current Ubuntu LTS image. The Lotus binaries are built inside the Lotus `Dockerfile` (currently a Debian trixie builder) and are dynamically linked against glibc, so the host needs a glibc that provides every versioned symbol the binaries reference. As of [lotus#13785](https://github.com/filecoin-project/lotus/pull/13785) the highest required symbol version is `GLIBC_2.39`, which Ubuntu 24.04 satisfies; Ubuntu 20.04 (glibc 2.31) does not. To check a freshly built binary: `objdump -T lotus | grep -o 'GLIBC_[0-9.]*' | sort -Vu | tail -1`.

### Pick a Lotus ref that builds

The workflow clones the given Lotus ref and builds it with the Lotus `Dockerfile` using `GOFLAGS=-tags=butterflynet`. If the ref is behind `master`, it may fail to build for reasons unrelated to the network (for example, a Docker base image whose apt repositories have gone end-of-life). Rebase or merge `master` into the branch first if the build step fails with apt or Docker errors.

For a network upgrade, the branch also needs the Butterfly upgrade height set to a positive epoch, otherwise the network never upgrades. Upgrade heights are compile-time constants in `build/buildconstants/params_butterfly.go`; there is no environment override.

### SSH access for yourself

The reset (and the `update_ssh_keys.yml` playbook) installs the public keys listed under `ssh_keys_access` in the inventory `hosts.yml`. To log in to the hosts yourself, add your public key as `ansible/roles/ssh_keys/files/public-keys/<your-github-handle>` and add the handle to `ssh_keys_access`. Log in as `ubuntu`.

## Resetting the Butterfly network

The workflow is [Lotus Ansible Reset Careful](https://github.com/filecoin-project/lotus-infra/actions/workflows/lotus-ansible-reset.yaml). Its inputs are:

- **Use workflow from**: the lotus-infra branch to run. Use `main` unless you have infra changes on a branch (for example, a new AMI or SSH key) that the reset needs.
- **Network**: `butterflynet`.
- **Lotus git ref**: the Lotus branch, tag, or commit to deploy.
- **Dry-run changes**: runs ansible in check mode. See the note below before relying on it.
- **Verbose ansible output**: optional.

### Dry-run Butterfly network reset

On hosts that have been provisioned before, it is recommended to do a dry run first to confirm the workflow completes end to end (Lotus build, SSH access, ansible):

1. Open the workflow, select **Run workflow**.
2. Fill in **Lotus git ref**.
3. Leave **Dry-run changes** checked and click **Run workflow**.

Note: a dry run does not work on freshly created hosts. Ansible check mode reports the `fc` group as created without creating it, so the next task fails on every host with `Group fc does not exist`. On fresh hosts, skip the dry run and go straight to the actual reset; there is nothing on the hosts to lose.

### Actual Butterfly network reset

1. Open the workflow, select **Run workflow**.
2. Fill in **Lotus git ref**.
3. Uncheck **Dry-run changes** and click **Run workflow**.

The real reset also sets up nginx for the faucet, Prometheus metrics, Promtail log forwarding, reboots the hosts, and captures the new genesis and a bundle of changed files as the `reset-artifacts` workflow artifact.

## Backfilling changes

### Why this is needed

A Lotus binary built with `-tags=butterflynet` embeds `build/genesis/butterflynet.car.zst` (via `build/genesis.go`) and initialises its chain from it on first start. A reset creates a brand new genesis, so until the new file is committed to Lotus, anyone who builds Lotus for butterflynet gets the old genesis and ends up on a chain of their own, unable to sync with the network. Committing the genesis is what makes the reset usable by Forest, other implementers, and anyone not on the reset hosts.

The bootstrap peer list (`build/bootstrap/butterflynet.pi`) no longer needs updating. Since September 2024 it contains a single `/dnsaddr/bootstrap.butterfly.fildev.network` entry, and the reset script updates the `_dnsaddr` TXT record in Route53 with the new bootstrap peer IDs. The reset does overwrite the local `.pi` with explicit addresses (so it shows up as a changed file in the artifact); do not commit that version.

### Downloading Artifacts

1. Navigate to [Lotus Ansible Reset Careful](https://github.com/filecoin-project/lotus-infra/actions/workflows/lotus-ansible-reset.yaml) in GitHub Actions, and click into your completed workflow.

2. Download the `reset-artifacts` at the bottom of the page. It contains:
   - `genesis.car`: the new genesis, fetched from preminer-0. This is the file you need.
   - `lotus.tar`: tracked files in the Lotus checkout that the reset modified (currently just `butterflynet.pi`, which you should not commit; see above).
   - `lotus-infra.tar`: tracked files in this repo that the reset modified, if any.

### Committing Artifacts to Lotus

1. Checkout the branch that you used for deploying the Butterfly network.

2. Prepare the new `butterflynet.car.zst` from the artifact's `genesis.car`:
   1. Remove the built-in actors WASM bundle blocks from the car. Lotus already embeds the actors bundle, so shipping them again only bloats the file. Install [go-car](https://github.com/ipld/go-car/) for the `car` command, then: `car ls genesis.car | grep ^bafk2bz | car filter --inverse genesis.car butterflynet.car`. This writes a new `butterflynet.car` in the current directory.
   2. Compress it: `zstd -19 butterflynet.car`.
   3. Sanity check: `car root butterflynet.car` must equal the genesis block CID the network reports (`lotus chain list --height 0 --count 1` on any host), and the artifact's `genesis.car` should have the same checksum as `/var/lib/lotus/genesis.car` on preminer-0. For reference, the 2026-09-17 reset went from a 9.2 MB `genesis.car` (7171 blocks, 16 of them actors WASM) to a 1.5 MB filtered car and a 0.5 MB `.zst`. The filter is not required for correctness (the file on master at the time still contained the WASM blocks and worked), but it makes the committed file about three times smaller.

3. Replace `build/genesis/butterflynet.car.zst` in Lotus with the new file and open a PR against `master` (and against any release branch that will be built for butterflynet).

👉 Example: [lotus#12966](https://github.com/filecoin-project/lotus/pull/12966) (March 2025) replaced `butterflynet.car.zst` and adjusted `params_butterfly.go` in the same PR. The older [lotus#12266](https://github.com/filecoin-project/lotus/pull/12266) predates zstd compression and dnsaddr, so its file list is no longer what to copy.

## Manual upgrade testing

After a reset, each upgrade's tracking doc has a "Generic Butterfly manual testing items" table (miner
setup, sector pledge/terminate/extend/batch, actor withdraw/control-address changes) that's meant to be
re-run every time, independent of what the specific upgrade changes. `scripts/butterfly_manual_testing.bash`
automates that table against a throwaway miner on a non-preminer host (scratch-0 or toolshed-1; never a
preminer, for the same reasons as the params-copying note above plus not wanting a disposable test
miner sharing a preminer's `LOTUS_PATH`) and prints doc-ready command/output blocks for each item.

## Tearing down the Butterfly network

When Butterfly testing for an upgrade is finished, destroy the hosts with terraform rather than from the AWS console, so the terraform state stays accurate:

```bash
cd terraform/testnets/deployments/butterfly_network
terraform destroy \
  -target=module.butterflynet.module.preminers.aws_instance.node \
  -target=module.butterflynet.module.preminers.aws_route53_record.node \
  -target=module.butterflynet.module.bootstrappers.aws_instance.node \
  -target=module.butterflynet.module.bootstrappers.aws_route53_record.node \
  -target=module.butterflynet.module.toolshed.aws_instance.node \
  -target=module.butterflynet.module.toolshed.aws_route53_record.node \
  -target=module.butterflynet.module.scratch.aws_instance.node \
  -target=module.butterflynet.module.scratch.aws_route53_record.node
```

Target the instances and their per-host A records only. Removing the A records too means the hostnames stop resolving to released IPs that AWS may hand to someone else. Destroying all of `module.butterflynet` would also remove the Butterfly DNS zone and security groups. This leaves the VPC, DNS zone, S3 bucket, and IAM roles in place for the next reset. If the hosts were terminated some other way, run `terraform plan` and let the next `terraform apply` reconcile the state. Record the teardown in the network upgrade tracking doc so the next upgrade knows to recreate the hosts.
