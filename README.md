# Lotus Infrastructure

A repository holding Lotus related infrastructure

## Terraform

### Miners

Located in `terraform/devnet/miners` this manages packet.net machines to be used as miners.

`cp terraform.tfvars.example terraform.tfvars` in the `miners` directory and fill out values to be able to run terraform.

Uses remote state, so `AWS_ACCESS_KEY_ID` and `AWS_ACCESS_KEY_ID` must also be exported with credentials allowing access to S3 bucket `filecoin-terraform-state` in `filecoin` AWS account.

## Kubernetes

### Lotus Grafana Dashboard

`kubernetes/helm/lotus-grafana` contains the Helm chart necessary to deploy the public Lotus Grafana dashboard

#### Installating or Upgrading

1. Check `values.yaml` for a reference of values that can be set. Create a new values file `release-name-values.yaml` and keep it handy. This is where you can override any default values found in the chart.
1. `helm upgrade --install -f release-name-values.yaml --namespace monitoring <release-name> .` - choose a <release-name> not already present if installing for first time. Check by running `helm ls`
1. Check status of deploy by doing `kubectl --namespace monitoring get pods`
1. Accessing the public URL will not allow you to log-in. You must port-forward directly to the grafana pod in kubernetes to perform administrative tasks in Grafana.

    kubectl --namespace monitoring port-forward <grafana-pod> 3010:3000

This will make grafana reachable without nginx in front at http://localhost:3010
1. Grafana must be manually configured to add the Influxdb datasource and import the chain dashboard from a JSON dump
