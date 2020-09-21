data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.48.0"

  name                 = local.name
  azs                  = flatten([data.aws_availability_zones.available.names])
  cidr                 = var.cidr
  public_subnets       = flatten([var.public_subnets])
  enable_dns_hostnames = true
  enable_s3_endpoint   = true

  tags = "${merge(
    local.tags,
    local.subnet_tags,
    map("kubernetes.io/cluster/${local.name}", "shared")
  )}"
}
