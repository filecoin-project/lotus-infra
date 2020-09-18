Deployment

helm -n <namespace> upgrade --install <release-name> ./lotus-fullnode --set debug=false

Docker Images

Currently to use this helm chart you will need to build a docker container using the branch `feat/k8s-keystore-perms`.
This branch contains additions to the `lotus-shed` tool to support keystore file verification, as well as configurable
jwt token permissions.

NOTE: We copy the keystore objects into a temporary runtime volume, this required because k8s does a multi layer symlink
dance and there is not a trivial way to allow lotus to actually traverse this without leaking to many details.

Currently this chart does not support the generation of wallets on startup, nor does this chart enable users to create
new keystore object as the keystore is readonly.

This chart also does not self support editing of secrets and any partial key rotations must be done through the kubectl
command line. The pod must be deleted for secrets to be updated in part because we must copy keystore files, ad the token
uses a subPath on the volume mount.
