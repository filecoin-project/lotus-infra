Additional resources installed in this namespace

- secret `s3-access`
- secret `lotus-jwt`

### lotus-jwt

The jwt token is created following the guide in the [development documentation](https://github.com/filecoin-project/filecoin-chain-archiver/blob/main/docs/DEVELOPMENT.md#creating-a-shared-jwt-token). The jwt requires `read` and `admin` privileges.

### s3-access

The s3 access is create using the aws cli.

```
aws --profile mainnet iam create-access-key --user-name s3-user-filecoin-snapshots-calibrationnet > s3-iam-user-access-calibration.json
kubectl create secret generic s3-access --from-literal=ACCESS_KEY=(cat s3-iam-user-access-calibration.json | jq -r '.AccessKey.AccessKeyId') --from-literal=SECRET_KEY=(cat s3-iam-user-access-calibration.json | jq -r '.AccessKey.SecretAccessKey')
```

The `s3-iam-user-access-calibration.json` is stored in the fil-infra 1password vault.
