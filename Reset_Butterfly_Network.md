# Reset Butterfly Network

## Summary

This runbook is intented for maintainers of the Lotus-Infra repo, and provides instructions on how to reset the Butterfly network infrastructure. It assumes that properly configured branches or tags has been made with the correct network parameters in Lotus. This runbook does not go over how to configure the Butterfly network

## General Information

A list of hosts for the butterfly network infrastructure and their roles can be found [here](https://github.com/filecoin-project/lotus-infra/blob/master/ansible/inventories/butterfly.fildev.network/hosts.yml).

## Resetting the network

### Start Network Reset Workflow

1. Navigate to [trigger devnet-reset workflow.](https://github.com/filecoin-project/lotus-infra/actions/workflows/trigger-devnet-reset.yaml)

2. Select **Run Workflow**

3. Fill out the **lotus tag** field with the desired branch or tag to be used for the deployment of the Butterfly-network.

4. Click **Run Workflow**

### Monitor Network Reset

1. Navigate to CircleCI and monitor your `api-lotus-ansible-reset-careful` workflow. Once `lotus-ansible-reset-careful-check` has completed, approve the Butterfly-network reset by clicking the `reset-approval` workflow step.

2. Wait and confirm that the the last `lotus-ansible-reset-careful` job to finish.

## Backfilling changes

### Downloading Artifacts

1. Click on the last workflow step **ansible-reset-careful**.

2. Clic the **ARTIFACTS** tab.

3. Download the lotus.tar file and take note of the
downloaded file name.

### Committing Artifacts to Lotus

1. Checkout the branch that you used for deploying the Butterfly-network,

2. Extract the `lotus.tar` file.

3. Commit the new `genesis/butterflynet.car` file to `https://github.com/filecoin-project/lotus/tree/master/build/genesis` replacing the old `butterflynet.car` file.

4. Commit the new `bootstrap/butterflynet.pi` file to `https://github.com/filecoin-project/lotus/tree/master/build/bootstrap`replacing the old butterflynet.pi file.
