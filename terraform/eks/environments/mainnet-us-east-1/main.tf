terraform {
  backend "s3" {
    bucket         = "filecoin-mainnet-terraform-state"
    key            = "filecoin-mainnet-eks-us-east-1.tfstate"
    dynamodb_table = "filecoin-mainnet-terraform-state"
    region         = "us-east-1"
    profile        = "mainnet"
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
  azs             = var.azs
}

resource "aws_subnet" "workers" {
  for_each                = toset(var.public_subnets_workers)
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = each.value
  tags                    = local.subnet_tags
  map_public_ip_on_launch = true
  availability_zone       = var.azs[index(var.public_subnets_workers, each.value)]
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_route_table_association" "workers" {
  for_each       = aws_subnet.workers
  subnet_id      = each.value.id
  route_table_id = module.vpc.public_route_table_ids[0]
}


locals {
  node_groups = {
    // These nodes are dedicated to running the bootstrap daemons they are special because
    // we need to ensure that two daemons do not run on the same k8s node to ensure ip
    // colocation does not occure.
    "0" = {
      instance_type    = "c5.4xlarge"
      key_name         = var.key_name
      desired_capacity = var.worker_count_open
      min_capacity     = "3"
      max_capacity     = "50"
      k8s_labels = {
        mode = "open"
      }
    },
    // These are general purpose compute for all other pods in the cluster.
    "1" = {
      instance_type    = "c5.4xlarge"
      key_name         = var.key_name
      desired_capacity = var.worker_count_restricted
      min_capacity     = "1"
      max_capacity     = "50"
      k8s_labels = {
        mode = "restricted"
      }
    },
    // These nodes are dedicated to running the fullnode daemons that provide api access to
    // other services running in the cluster
    "2" = {
      instance_type    = "r5.4xlarge"
      key_name         = var.key_name
      desired_capacity = 5
      min_capacity     = "3"
      max_capacity     = "50"
      k8s_labels = {
        mode = "restricted"
      }
    },
    "3" = {
      instance_type    = "r5.4xlarge"
      key_name         = var.key_name
      desired_capacity = 5
      min_capacity     = "3"
      max_capacity     = "50"
      k8s_labels = {
        mode = "open"
      }
      subnets = [
        for subnet in aws_subnet.workers :
        subnet.id
      ]
    },
  }
  subnet_tags = {
    "kubernetes.io/role/alb-ingress"          = "1"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/${var.prefix}-eks" = "shared"
    "Name"                                    = "${var.prefix}-worker"
  }
  acm_enabled = 1
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
  external_dns_fqdn                          = "${var.prefix}.${var.external_dns_fqdn}"
  node_groups                                = local.node_groups
  security_group_ids                         = module.vpc.security_group_ids
}
