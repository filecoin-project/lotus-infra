don't install these on a real system.

These CRDs are provided to prevent CRD-related failures on test clusters.
They do not provide any real functionality.

For example, many applications require monitoring provided by a ServiceMonitor.
applying this directory will install the ServiceMonitor CRD, but it does not
install any real monitoring software

This directory was generated from one of our existing real clusters.

```
for CRD in $(kubectl --context us-east-2-dev get crds | grep -Ev NAME\|weave\|flux | cut -d\  -f1)
do
kubectl --context us-east-2-dev get crds $CRD -o yaml > $CRD.yaml
done
```
