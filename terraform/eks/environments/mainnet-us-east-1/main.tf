terraform {
  backend "s3" {
    bucket         = "filecoin-mainnet-terraform-state"
    key            = "filecoin-mainnet-eks-us-east-1.tfstate"
    dynamodb_table = "filecoin-mainnet-terraform-state"
    region         = "us-east-1"
    profile        = "mainnet"
  }
}

locals {
  node_groups = [
    // These nodes are dedicated to running the bootstrap daemons they are special because
    // we need to ensure that two daemons do not run on the same k8s node to ensure ip
    // colocation does not occure.
    {
      instance_type = "c5.4xlarge"
      key_name      = var.key_name
      desired_capacity = var.worker_count_open
      min_capacity     = "3"
      max_capacity     = "50"
      k8s_labels = {
        mode = "open"
      }
    },
    // These are general purpose compute for all other pods in the cluster.
    {
      instance_type = "c5.4xlarge"
      key_name      = var.key_name
      desired_capacity = var.worker_count_restricted
      min_capacity     = "3"
      max_capacity     = "50"
      k8s_labels = {
        mode = "restricted"
      }
    },
    // These nodes are dedicated to running the fullnode daemons that provide api access to
    // other services running in the cluster
    {
      instance_type = "r5.4xlarge"
      key_name      = var.key_name
      desired_capacity = 5
      min_capacity     = "3"
      max_capacity     = "50"
      k8s_labels = {
        mode = "restricted"
      }
    },
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
