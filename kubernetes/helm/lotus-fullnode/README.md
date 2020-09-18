Deployment

helm -n <namespace> upgrade --install <release-name> ./lotus-fullnode --set debug=false

Docker Images

The docker image uses must be built with the goflag `-tags=k8s_keystore_perms` to change permission requirements on the
keystore. This flag is currently only supported in the lotus branch `feat/k8s-keystore-perms`. This branch also
container additional additions to the `lotus-shed` tool to support keystore file verification, as well as configurable
jwt token permissions.

NOTE: The keystore permissions are completely removed. This is required because k8s does a multi layer symlink dance
and there is not a trivial way to allow lotus to actually traverse this without leaking to many details. Instead
we opt to completely disable the permissions checks in lotus and favor instead to check them via init containers in k8s.

Currently this chart does not support the generation of wallets on startup, nor does this chart enable users to create
new keystore object as the keystore is readonly.

This chart also does not self support editing of secrets and any partial key rotations must be done through the kubectl
command line. However, the object under the `keystore` will be updated in place as we are mounting the entire volume to
the `$LOTUS_PATH/keystore`. This does not apply to the token, as it is a subPath volume mount.
