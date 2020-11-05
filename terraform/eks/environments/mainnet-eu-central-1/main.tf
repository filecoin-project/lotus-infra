terraform {
  backend "s3" {
    bucket         = "filecoin-mainnet-terraform-state"
    key            = "filecoin-mainnet-eks-eu-central-1.tfstate"
    dynamodb_table = "filecoin-mainnet-terraform-state"
    region         = "us-east-1"
    profile        = "mainnet"
  }
}

locals {
  node_groups = [
    {
      instance_type = "c5.4xlarge"
      key_name      = var.key_name
      # additional_userdata  = "aws s3 cp s3://filecoin-proof-parameters /opt/filecoin-proof-parameters --region us-east-1 --recursive --no-sign-request"
      desired_capacity = var.worker_count_open
      min_capacity     = "1"
      max_capacity     = "50"
      k8s_labels = {
        mode = "open"
      }
    }
  ]
  acm_enabled = 1
}

module "main" {
  source = "../../resources"

  aws_profile                                = var.aws_profile
  prefix                                     = var.prefix
  region                                     = var.region
  cidr                                       = var.cidr
  private_subnets                            = var.private_subnets
  public_subnets                             = var.public_subnets
  eks_iam_usernames                          = var.eks_iam_usernames
  kubeconfig_aws_authenticator_env_variables = var.kubeconfig_aws_authenticator_env_variables
  key_name                                   = var.key_name
  k8s_version                                = var.k8s_version
  worker_count_open                          = var.worker_count_open
  worker_count_restricted                    = var.worker_count_restricted
  external_dns_zone_id                       = var.external_dns_zone_id
  external_dns_fqdn                          = var.external_dns_fqdn
  node_groups                                = local.node_groups
  #acm_enabled                                = local.acm_enabled
}
