------------------------------------

#### What k8s infrastructure should be updated during lotus upgrades?

us-east-1:
	ntwk-mainnet-api:
		* gateway
		* api
	ntwk-mainnet-fullnode
		* all fullnode nodes
	ntwk-mainnet-bootstrap
		* all bootstrap nodes
	ntwk-mainnet-disputer
		* all disputer nodes
	ntwk-mainnet-snapshot
		* all lotus nodes
	ntwk-calibnet-snapshot
		* all lotus nodes

us-east-2-dev:
	ntwk-mainnet-api:
		* gateway
		* api
	ntwk-mainnet-fullnode
		* all fullnode nodes
	ntwk-mainnet-bootstrap
		* all bootstrap nodes
	ntwk-mainnet-disputer
		* all disputer nodes

eu-central-1:
	ntwk-mainnet-bootstrap
		* all bootstrap nodes
	ntwk-mainnet-disputer
		* all disputer nodes

ap-southeast-1:
	ntwk-mainnet-bootstrap
		* all bootstrap nodes
	ntwk-mainnet-disputer
		* all disputer nodes


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

_Note: when you run helm.bash, it will spit out a bunch of commands. You will want to only run the commands you need to
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

------------------------------------

#### Verifying upgrades

If you have only upgraded a single instance, you can verify the upgrade has occurred by looking at the pod that has been deployed.

There are many ways to do this; here are a few ways to get straight to the point without having to sift through a whole lot of yaml.

<p class=callout info>
Regardless of whether you use a dashboard or kubectl commands to verify the upgrade, you should keep the dashboard open during upgrades.
Keeping the dashboard open allows you to look for other issues, e.g. nodes falling out of sync.
</p>

##### using a dashboard.

Go to this dashboard: https://protocollabs.grafana.net/d/QjaTQUKMk/lotus-namespaces?orgId=1

1. At the top of the dashboard, make sure the namespace and datasource are set correctly.
2. Find the section of the dashboard titled "Version"
3. Verify the version has been upgraded as you expected it to.


##### using kubectl commands 

Get the image of a single pod

```
kubectl -n ntwk-mainnet-fullnode get pods fullnode-0-lotus-0 -o jsonpath="{.spec.containers[*].image}"
```

Get the images of the container in a single interesting namespace.

```
kubectl -n ntwk-mainnet-fullnode get pods -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | column -t
```

Look at the images for all namespaces for the entire cluster.

```
kubectl  get pods -o jsonpath='{range .items[*]}{"\n"}{.metadata.namespace}{":\t"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' --all-namespaces -l app=lotus-fullnode-app | column -t
```


