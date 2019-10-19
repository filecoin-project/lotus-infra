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
1. Grafana must be manually configured to add the Influxdb datasource and import the chain dashboard from a JSON dump. Access grafana at the URL you configured in `domainInternal` value.

#### Public and Internal Dashboards

There are two domains configured for the dashboard, one intended for public use and another for internal use by PL.

Public Dashboard is accessible at URL configured in `domain` helm chart value. This URL can be shared publicly, as it maps to the nginx container that limits access to Grafana.

An internal dashboard is accessible at URL configured in `domainInternal` helm chart value that allows access to grafana unfettered by nginx.

*DO NOT SHARE THE INTERNAL DOMAIN PUBLICLY AS IT COULD OPEN UP INFLUXDB TO DOS ATTACKS*
