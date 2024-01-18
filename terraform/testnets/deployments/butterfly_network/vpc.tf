module "fildev_network_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.2.0"

  providers = {
    aws = aws.us-east-1
  }

  name                               = "fildev-network-vpc"
  azs                                = ["us-east-1a", "us-east-1b", "us-east-1c"]
  cidr                               = local.cidr
  public_subnets                     = local.public_subnets
  database_subnets                   = local.private_subnets
  enable_dns_support                 = true
  enable_dns_hostnames               = true
  create_database_subnet_group       = true
  create_database_subnet_route_table = true
  map_public_ip_on_launch            = true
}
