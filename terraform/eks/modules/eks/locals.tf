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
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/travis"
      username = "travis"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cory"
      username = "cory"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/iand"
      username = "iand"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/frrist"
      username = "frrist"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/mg"
      username = "mg"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/lanzafame"
      username = "lanzafame"
      groups   = ["system:masters"]
    },
  ]

  tags = {
    "Environment" = "${local.name}"
    "Terraform"   = "yes"
  }
}
