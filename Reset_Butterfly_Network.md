# Reset Butterfly Network

## Summary

This runbook is intended for maintainers of the Lotus-Infra repo and provides instructions on how to reset the Butterfly network infrastructure. It assumes that properly configured branches or tags have been made with the correct network parameters in Lotus. This runbook does not cover how to configure the Butterfly network.

## General Information

- A list of hosts for the Butterfly network infrastructure and their roles can be found [here](https://github.com/filecoin-project/lotus-infra/blob/main/ansible/inventories/butterfly.fildev.network/hosts.yml).
- The instances running the Butterfly network infrastructure are in the FilOz AWS account (us-east-1). FilOz members can get credentials to log in and confirm that these are running in their 1Password account.
- The hosts are normally torn down after an upgrade's Butterfly testing is complete to save cost (see [Tearing down the Butterfly network](#tearing-down-the-butterfly-network)). Do not assume they exist; check first (see below).
- A reset on hosts that have been provisioned before takes roughly 45 minutes of workflow time, most of it building Lotus.
- A reset on freshly created hosts takes closer to two hours. Each preminer downloads about 24 GB of proof parameters for 512MiB sectors (the SnapDeals `empty-sector-update` file alone is 21.7 GB). Where they come from is decided by [go-paramfetch](https://github.com/filecoin-project/go-paramfetch), which Lotus uses for `fetch-params`; the inventory's `lotus_ipfs_gateway` variable overrides its default. The parameters live in `/var/tmp/filecoin-proof-parameters` on each host and are lost when the hosts are destroyed, so this cost is paid once per teardown.

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

### Downloading Artifacts

1. Navigate to [Lotus Ansible Reset Careful](https://github.com/filecoin-project/lotus-infra/actions/workflows/lotus-ansible-reset.yaml) in GitHub Actions, and click into your completed workflow.

2. Download the `reset-artifacts` at the bottom of the page and take note of the downloaded file name.

### Committing Artifacts to Lotus

1. Checkout the branch that you used for deploying the Butterfly network.

2. Extract the `lotus.tar` file inside of your downloaded `reset-artifacts`.

3. Prepare `build/genesis/butterflynet.car`:
   1. Remove built-in actors WASM compiles from the bundle *(install https://github.com/ipld/go-car/ for the `car` command)*: `car ls build/genesis/butterflynet.car | grep ^bafk2bz | car filter --inverse build/genesis/butterflynet.car butterflynet.car` - this will result in a new `butterflynet.car` in the current working directory.
   2. Compress `butterflynet.car` with `zstd -19 butterflynet.car`.

4. Commit the new `butterflynet.car.zst` file to `https://github.com/filecoin-project/lotus/tree/master/build/genesis` replacing the old `butterflynet.car.zst` file.

👉 Example of a PR submitting the artifacts to [Lotus can be seen here](https://github.com/filecoin-project/lotus/pull/12266).

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
