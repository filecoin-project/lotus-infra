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
