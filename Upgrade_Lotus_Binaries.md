# Reset Butterfly Network

## Summary

This runbook is intented for maintainers of the Lotus-Infra repo, and provides instructions on how to swap binaries across the butterfly network with ones built from a given commit sha.

## General Information

A list of hosts for the butterfly network infrastructure and their roles can be found [here](https://github.com/filecoin-project/lotus-infra/blob/main/ansible/inventories/butterfly.fildev.network/hosts.yml).

## Upgrade Lotus Binaries

### Start Network Reset Workflow

1. Navigate to [Upgrade Lotus Binaries](https://github.com/filecoin-project/lotus-infra/actions/workflows/upgrade-fildev-network-binaries.yaml).

2. Click the **Run Workflow** button in the right-hand corner.

3. Fill out the **Lotus git ref** field with the desired commit to upgrade the binaries to.

4. Click **Run Workflow** with the `Dry-run changes` option checked, and confirm that everything goes as expected. Once you have run a dry-run, uncheck the `Dry-run changes` option and run the workflow again.

Confirm that the workflow completes successfully, and proceed with the actual Butterfly network reset.

By following these steps, you can ensure that the binaries for Butterfly network is swapped out easily. The whole workflow should take approximately 10 minutes. 