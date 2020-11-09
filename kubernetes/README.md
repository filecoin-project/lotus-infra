# Updating Mainnet Infra

Each EKS cluster is broken out into their own folder, the top level of the folder contains k8s resources for the cluster.

Along side these raw k8s resources there is a `helm` folder which contains a `config.yaml` which describes the helm deployments
in the cluster. The `helm.bash` script in this folder can be used to generate the helm commands to run a deployment for each
cluster.

Value files for each entry of the `config.yaml` are stored alongside the configuration file in the form of:

_Note: <chart> here refers to the helm argument, and the `chart` value in the config.toml. So for the `lotus-fullnode`, this
would be `filecoin/lotus-fullnode`._

```
<namespace>/<chart>/<value-file>.yaml
```

NOTE: You will want to install `helm-diff`, it's a small plugin that shows the changes that helm commands will make.
Download from: https://github.com/databus23/helm-diff

-----------------------------------

#### Updating lotus version

_Note: Currently there is a job created as part of the lotus-fullnode chart to create the jwt and libp2p secrets when they are
enabled and no secret name is provided. This bit of code doesn't correctly detect the existing job, which requires that it is
deleted first._

1. Find the correct docker tag that you need to deploy
2. Update the `tag` value for the chart
   eg: Updating the daemons in the `ntwk-mainnet-fullnode`, you'd change need to update
   `mainnet-us-east-1-eks/helm/ntwk-mainnet-fullnode/filecoin/lotus-fullnode/base.yaml`
3. Run the `helm.bash` in diff mode for the cluster, and test execute the upgrade using for the selected helm release.
   ```
   $ ./helm.bash --cluster mainnet-us-east-1-ek --diff
   ```
4. Delete the jobs for the release.
   ```
   $ kubectl get jobs
   $ kubectl delete job <release>-jwt-secrets-creator
   $ kubectl delete job <release>-libp2p-secrets-creator
   ```
5. Next generate the helm command without diff and apply the changes
   ```
   $ ./helm.bash --cluster mainnet-us-east-1-ek
   ```
6. Verify that the pod has terminated / restarted. If it hasn't delete the pod for the release
   ```
   $ kubectl delete pod <release>-lotus-0
   ```
