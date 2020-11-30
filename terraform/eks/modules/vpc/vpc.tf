module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "2.48.0"
  name                 = local.name
  azs                  = var.azs
  cidr                 = var.cidr
  public_subnets       = flatten([var.public_subnets])
  enable_dns_hostnames = true

  tags = "${merge(
    local.tags,
    local.subnet_tags,
    map("kubernetes.io/cluster/${local.name}", "shared")
  )}"
}
