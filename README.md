# Lotus Infrastructure

A repository holding Lotus related infrastructure

## Terraform

### Miners

Located in `terraform/devnet/miners` this manages packet.net machines to be used as miners.

`cp terraform.tfvars.example terraform.tfvars` in the `miners` directory and fill out values to be able to run terraform.

Uses remote state, so `AWS_ACCESS_KEY_ID` and `AWS_ACCESS_KEY_ID` must also be exported with credentials allowing access to S3 bucket `filecoin-terraform-state` in `filecoin` AWS account.
