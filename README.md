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
=======

### Lotus Stats

Lotus stats is a service which monitors chain head events and writes chain data to an influx database.

To setup correctly a `lotus-stats-values.yaml` file must be created with the following information filled out.
Values can be found in the `filecoin dev` vault under `InfluxDB lotus credentials` of 1password.

The default database is `lotus`

```
InfluxAddr: "http://<host>:<port>"
InfluxUser: "<user>"
InfluxPass: "<pass>"
```

```
$ helm upgrade --install -f lotus-stats-values.yaml --namespace lotus-stats lotus-stats kubernetes/helm/lotus-stats
```

#### Creating containers

```
$ ./scripts/lotus-stats.bash master
```

#### Resetting for a new network

Once the network is released and the `master` branch of `lotus` can be built to join:

0) Take down the current `lotus-stats` service 

```
$ helm delete --purge lotus-stats
$ kubectl --namespace lotus-stats delete pvc --all
```

1) Drop the influxdb database `lotus` and recreate it.

This is currently a manual step we are taking.

https://hillvalley-1b1e0a69.influxcloud.net/sources/0/admin-influxdb/databases

2) Build new images and create `lotus-stats` service

_Make sure you are logged into ecr `eval $(aws --profile filecoin --region us-east-1 ecr --no-include-email get-login)`_

```
$ ./scripts/lotus-stats.bash master
$ helm upgrade --install -f lotus-stats-values.yaml --namespace lotus-stats lotus-stats kubernetes/helm/lotus-stats
```
