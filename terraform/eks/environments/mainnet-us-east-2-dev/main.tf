terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "filecoin-mainnet-eks-us-east-2-dev.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  aws_profile     = var.aws_profile
  prefix          = var.prefix
  region          = var.region
  cidr            = var.cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}


resource "aws_subnet" "workers" {
  for_each                = var.public_subnets_workers
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = each.value
  tags                    = local.subnet_tags
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "workers" {
  for_each       = aws_subnet.workers
  subnet_id      = each.value.id
  route_table_id = module.vpc.public_route_table_ids[0]
}

locals {
  node_groups = [
    // These nodes are dedicated to running the fullnode daemons that provide api access to
    // other services running in the cluster
    {
      instance_type    = "r5.4xlarge"
      key_name         = var.key_name
      desired_capacity = 3
      min_capacity     = "3"
      max_capacity     = "50"
      k8s_labels       = {}
      subnets = [
        for subnet in aws_subnet.workers :
        subnet.id
      ]
    },
  ]
  acm_enabled = 1
  subnet_tags = {
    "kubernetes.io/role/alb-ingress"          = "1"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/${var.prefix}-eks" = "shared"
    "Name"                                    = "${var.prefix}-worker"
  }
}

module "eks" {
  source = "../../modules/eks"

  prefix                                     = var.prefix
  region                                     = var.region
  aws_profile                                = var.aws_profile
  vpc_id                                     = module.vpc.vpc_id
  public_subnets                             = module.vpc.public_subnet_ids
  private_subnets                            = module.vpc.private_subnet_ids
  eks_iam_usernames                          = var.eks_iam_usernames
  kubeconfig_aws_authenticator_env_variables = var.kubeconfig_aws_authenticator_env_variables
  key_name                                   = var.key_name
  k8s_version                                = var.k8s_version
  worker_count_open                          = var.worker_count_open
  worker_count_restricted                    = var.worker_count_restricted
  external_dns_zone_id                       = var.external_dns_zone_id
  external_dns_fqdn                          = var.external_dns_fqdn
  node_groups                                = local.node_groups
  security_group_ids                         = module.vpc.security_group_ids
}
