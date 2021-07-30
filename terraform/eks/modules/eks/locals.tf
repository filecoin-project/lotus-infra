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
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/travisperson"
      username = "travisperson"
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
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/hsanjuan"
      username = "hsanjuan"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/circleci-lotus"
      username = "circleci-lotus"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/hannah.howard"
      username = "hannah.howard"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/raulk"
      username = "raulk"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/willscott"
      username = "willscott"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/circleci-sentinel-infra"
      username = "circleci-sentinel-infra"
      groups   = ["system:masters"]
    },
  ]

  map_roles = [
    {
      rolearn = ""
      username = "ntwk-mainnet-fullnode-admin"
      groups = ["ntwk-mainnet-fullnode-admin"]
    },
    {
      rolearn = ""
      username = "ntwk-mainnet-fullnode-exec"
      groups = ["ntwk-mainnet-fullnode-exec"]
    },
    {
      rolearn = ""
      username = "ntwk-butterfly-fullnode-admin"
      groups = ["ntwk-butterfly-fullnode-admin"]
    },
    {
      rolearn = ""
      username = "ntwk-butterfly-fullnode-exec"
      groups = ["ntwk-butterfly-fullnode-exec"]
    },
    {
      rolearn = ""
      username = "ntwk-calibnet-fullnode-admin"
      groups = ["ntwk-calibnet-fullnode-admin"]
    },
    {
      rolearn = ""
      username = "ntwk-calibnet-fullnode-exec"
      groups = ["ntwk-calibnet-fullnode-exec"]
    },
    {
      rolearn = ""
      username = "ntwk-mainnet-dealbot-admin"
      groups = ["ntwk-mainnet-dealbot-admin"]
    },
    {
      rolearn = ""
      username = "ntwk-mainnet-dealbot-exec"
      groups = ["ntwk-mainnet-dealbot-exec"]
    },
    {
      rolearn = ""
      username = "ntwk-nerpanet-dealbot-admin"
      groups = ["ntwk-nerpanet-dealbot-admin"]
    },
    {
      rolearn = ""
      username = "ntwk-nerpanet-dealbot-exec"
      groups = ["ntwk-nerpanet-dealbot-exec"]
    },
  ]

  tags = {
    "Environment" = "${local.name}"
    "Terraform"   = "yes"
  }
}
