data "aws_availability_zones" "available" {}



module "lotus_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name                 = "lotus_vpc"
  azs                  = data.aws_availability_zones.available.names
  cidr                 = local.cidr
  public_subnets       = local.public_subnets
  private_subnets      = local.private_subnets
  enable_dns_support = true
  enable_dns_hostnames = true
}
