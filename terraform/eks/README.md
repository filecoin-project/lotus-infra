# EKS Kubernetes

Terraform configuration to bring up a Kubernetes cluster. It creates a new VPC and configures an EKS Kubernetes cluster.

Also installs the following deployments:
- [external-dns][https://github.com/kubernetes-incubator/external-dns]

[EKS]: https://aws.amazon.com/eks/

## Requirements

You will need to install the following:

- [terraform][] v0.12.x
- [aws-iam-authenticator][] helper binary
- [kubectl][] client v1.17.x
- [helm][] client v3.1+

[Terraform]: https://www.terraform.io/
[aws-iam-authenticator]: https://docs.aws.amazon.com/eks/latest/userguide/configure-kubectl.html
[kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-homebrew-on-macos
[helm]: https://docs.helm.sh/using_helm/#installing-the-helm-client

You will also need the following environment variables set for `terraform`
and `aws` to authenticate with AWS:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Deployment

This terraform uses the concept of "environments" to manage state.

*All `terraform` commands should be run in `enviroment/<type>`*

### Mainnet us-east-2 Environment

The infra team maintains a stable, EKS cluster, intended for running Filecoin Mainnet.

Remote `s3` state is used so make sure no one else is running any updates at the same time.

This environment should be treated as a production environment and proper communication to the  team and relevant Engineering stakeholders should be done before doing any maintenance.

To make changes to this environment, follow these instructions.

#### Instructions

1. Change directories to `environment/mainnet-us-east-2`
1. Initialise state and modules for Terraform:

        terraform init
1. Follow global instructions below

### Local Environment

Whenever you need a personal EKS cluster and test environment, you can use the local environment and store state locally.

Be sure to tear down any local environment when not in use.

#### Instructions

1. Change directories to `environment/local`
1. Initialise state and modules for Terraform:

        terraform init
1. Create a terraform.tfvars file with any mandatory settings from variables.tf:

        prefix = "myname"
1. Follow global instructions below

## Global Instructions

### Kubernetes Authentication

This Kubernetes setup enables [RBAC]()

To grant Kubectl access, edit `resources/locals.tf` and ensure all IAM users are present in `map_users` property

### Terraform Apply

Create the infrastructure:

    terraform apply

### Running terraform with AWS profiles

Additional configuration is needed to AWS CLI profile support

In `environment/<type>/terraform.tfvars`

```
kubeconfig_aws_authenticator_env_variables = {
  AWS_PROFILE = "filecoin"
}
```

In `environment/<type>/override.tf`

```
provider "aws" {
  profile = "filecoin"
}`
```

### Manual steps

It may be possible to automate these in the future.

#### Configure kubectl

Configure `kubectl` to point at and authenticate with the cluster: https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html

## Teardown

Make sure you're in the proper environment before proceeeding.

First ensure that you have deleted any Helm releases and orphaned resources
like persistent volumes.

Then tell Terraform to destroy everything:

    terraform destroy
