# Reset Butterfly Network

## Summary

This runbook is intended for maintainers of the Lotus-Infra repo and provides instructions on how to reset the Butterfly network infrastructure. It assumes that properly configured branches or tags have been made with the correct network parameters in Lotus. This runbook does not cover how to configure the Butterfly network.

## General Information

- A list of hosts for the Butterfly network infrastructure and their roles can be found [here](https://github.com/filecoin-project/lotus-infra/blob/master/ansible/inventories/butterfly.fildev.network/hosts.yml).
- The instances running the Butterfly network infrastructure are in the FilOz AWS account. FilOz members can get credentials to log in and confirm that these are running in their 1Password account.

## Resetting the Butterfly network

Before fully resetting the Butterfly network, it is recommended to do a dry-run reset of the network to confirm that the workflow completes:

### Dry-run Butterfly network reset

1. Navigate to [Lotus Ansible Reset Careful](https://github.com/filecoin-project/lotus-infra/actions/workflows/lotus-ansible-reset.yaml) in GitHub Actions.

2. Select **Run workflow**.

3. Fill out the **lotus branch** field with the desired branch or tag to be used for the deployment of the Butterfly network.

4. Ensure that the `Run this workflow in dry-run mode first before setting to false` is set to `true` and click on the `Run workflow` button.

Confirm that the workflow completes successfully, and proceed with the actual Butterfly network reset.

### Actual Butterfly network reset

1. Navigate to [Lotus Ansible Reset Careful](https://github.com/filecoin-project/lotus-infra/actions/workflows/lotus-ansible-reset.yaml) in GitHub Actions.

2. Select **Run workflow**.

3. Fill out the **lotus branch** field with the desired branch or tag to be used for the deployment of the Butterfly network.

4. Ensure that the `Run this workflow in dry-run mode first before setting to false` is set to `false` and click on the `Run workflow` button.

## Backfilling changes

### Downloading Artifacts

1. Navigate to [Lotus Ansible Reset Careful](https://github.com/filecoin-project/lotus-infra/actions/workflows/lotus-ansible-reset.yaml) in GitHub Actions, and click into your completed workflow.

2. Download the `reset-artifacts` at the bottom of the page and take note of the downloaded file name.

### Committing Artifacts to Lotus

1. Checkout the branch that you used for deploying the Butterfly network.

2. Extract the `lotus.tar` file inside of your downloaded `reset-artifacts`.

3. Commit the new `genesis/butterflynet.car` file to `https://github.com/filecoin-project/lotus/tree/master/build/genesis`, replacing the old `butterflynet.car` file.

4. Commit the new `bootstrap/butterflynet.pi` file to `https://github.com/filecoin-project/lotus/tree/master/build/bootstrap`, replacing the old `butterflynet.pi` file.

👉 Example of a PR submitting the artifacts to [Lotus can be seen here](https://github.com/filecoin-project/lotus/pull/12266).