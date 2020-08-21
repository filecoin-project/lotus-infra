module "fildev_network_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  providers = {
    aws = aws.us-west-2
  }

  name                         = "fildev-network-vpc"
  azs                          = ["us-west-2a", "us-west-2b", "us-west-2c"]
  cidr                         = local.cidr
  public_subnets               = local.public_subnets
  database_subnets             = local.private_subnets
  enable_dns_support           = true
  enable_dns_hostnames         = true
  create_database_subnet_group = true
}

module "fildev_network_vpc_east" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  providers = {
    aws = aws.us-east-1
  }

  name                         = "fildev-network-vpc"
  azs                          = ["us-east-1b", "us-east-1c", "us-east-1d"]
  cidr                         = local.cidr
  public_subnets               = local.public_subnets
  database_subnets             = local.private_subnets
  enable_dns_support           = true
  enable_dns_hostnames         = true
  create_database_subnet_group = true
}
