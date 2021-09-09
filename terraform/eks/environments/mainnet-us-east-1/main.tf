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
    "2" = {
      instance_type    = "r5.4xlarge"
      key_name         = var.key_name
      desired_capacity = 6
      min_capacity     = "3"
      max_capacity     = "50"
    },
    "4" = {
      instance_type    = "r5.8xlarge"
      key_name         = var.key_name
      desired_capacity = 18
      min_capacity     = "3"
      max_capacity     = "50"
      subnets = [
        for subnet in aws_subnet.workers :
        subnet.id
      ]
    },
    "5" = {
      instance_type    = "r5.2xlarge"
      key_name         = "filecoin-mainnet"
      min_capacity     = "1"
      max_capacity     = "12"
      k8s_labels       = {
        "fil-infra.protocol.ai/node-type" = "lotus-standard"
      }
      subnets = [
        for subnet in aws_subnet.workers :
        subnet.id
      ],
      additional_tags = {
        "k8s.io/cluster-autoscaler/mainnet-us-east-1-eks" = "owned"
        "k8s.io/cluster-autoscaler/enabled" = "TRUE"
      }
    },
    "6" = {
      instance_type    = "r5.8xlarge"
      key_name         = "filecoin-mainnet"
      min_capacity     = "1"
      max_capacity     = "12"
      k8s_labels       = {
        "fil-infra.protocol.ai/node-type" = "lotus-high-memory"
      }
      subnets = [
        for subnet in aws_subnet.workers :
        subnet.id
      ],
      additional_tags = {
        "k8s.io/cluster-autoscaler/mainnet-ap-southeast-1-eks" = "owned"
        "k8s.io/cluster-autoscaler/enabled" = "TRUE"
      }
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
  external_dns_fqdn                          = "${var.external_dns_fqdn}"
  node_groups                                = local.node_groups
  security_group_ids                         = module.vpc.security_group_ids
}
