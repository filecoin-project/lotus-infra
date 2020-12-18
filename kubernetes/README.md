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

_Note: when you run helm.bash, it will spit out a bunch of command, you will want to only run the commands you need to
run to target the helm release you want to upgrade._

1. Find the correct docker tag that you need to deploy
2. Update the `tag` value for the chart
   eg: Updating the daemons in the `ntwk-mainnet-fullnode`, you'd change need to update
   `mainnet-us-east-1-eks/helm/ntwk-mainnet-fullnode/filecoin/lotus-fullnode/base.yaml`
3. Run the `helm.bash` in diff mode for the cluster, and test execute the upgrade using for the selected helm release.
   ```
   $ ./helm.bash --cluster mainnet-us-east-1-eks --diff
   ```
4. Next generate the helm command without diff and apply the changes
   ```
   $ ./helm.bash --cluster mainnet-us-east-1-eks
   ```
5. Verify that the pod has terminated / restarted. If it hasn't delete the pod for the release
   ```
   $ kubectl delete pod <release>-lotus-0
   ```
