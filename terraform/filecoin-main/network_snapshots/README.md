AWS iam user access keys are created using the output for the iam user and then the following command:

```
aws --profile mainnet iam create-access-key --user-name <iam-user>
```
