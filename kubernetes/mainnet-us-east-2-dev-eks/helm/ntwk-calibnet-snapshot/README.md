Additional resources installed in this namespace

- secret `r2-access`
- secret `lotus-jwt`

### lotus-jwt

The jwt token is created following the guide in the [development documentation](https://github.com/filecoin-project/filecoin-chain-archiver/blob/main/docs/DEVELOPMENT.md#creating-a-shared-jwt-token). The jwt requires `read` and `admin` privileges.

### r2-access

the r2 access is create through the cloudflare webui and stored under `snapshots: r2-read-write-snapshot-services-staging` in the fil-infra 1password vault.
