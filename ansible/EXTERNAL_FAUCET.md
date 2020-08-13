# External Faucet

The external faucet requires write access to the lotus node API. This means that it must have the
correct auth token. Currently to simplify deployments we are reusing the auth token. This means we
must import the auth token to the facuet node. This is done automatically through the `lotus_fullnode`
role.

Currently there isn't an easy way (for infra) to generate a jwt key and token. So this is a manual
process at the moment if it needs to be updated. To do this, just create a new lotus repo and extract
the jwt token (see `./roles/lotus_fullnode/vars/main.yml` for the `lotus_jwt_keyname`), this should be
present in `$LOTUS_PATH/keystore/`. The value is a json object, and must be base16 encoded.
Use `lotus-shed base16 $(cat $LOTUS_PATH/keystore/<lotus_jwt_keyname>)` to get this value. This is send
set as the `lotus_jwt_keyinfo` along with the `$LOTUS_PATH/token` as `lotus_jwt_token` as vars on the
`lotus_fullnode` role. To get the key imported makes sure to set `lotus_import_jwt` to `true`. For
current deployments this will automatically be set in the `lotus_devnet_provision` playbook if the
external faucet is enabled with `lotus_fountain_external` set to `true`.
