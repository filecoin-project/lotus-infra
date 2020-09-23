# Filecoin EKS Prometheus Operator

A values file to be used with
Compatible with [prometheus-operator](https://github.com/helm/charts/tree/master/stable/prometheus-operator) version 9.*.*

To install:
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm -n monitoring upgrade --install --values prometheus-operator-values.yaml monitoring stable/prometheus-operator
```

NOTE: the stable repo has recently been deprecated. this should be migrated at first opportunity
