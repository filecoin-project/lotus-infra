locals {
  name            = "${var.prefix}-eks"
  config_path     = "./"
  kubeconfig_path = "${local.config_path}kubeconfig_${local.name}"

  map_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/marcus"
      username = "marcus"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/travisperson"
      username = "travisperson"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cory"
      username = "cory"
      groups   = ["system:masters"]
    },
  ]

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
