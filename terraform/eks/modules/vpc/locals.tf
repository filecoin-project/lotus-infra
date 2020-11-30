locals {
  name = "${var.prefix}-eks"
  tags = {
    "Environment" = "${local.name}"
    "Terraform"   = "yes"
  }

  subnet_tags = {
    "kubernetes.io/role/alb-ingress"          = "1"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/${var.prefix}-eks" = "shared"
  }
}
