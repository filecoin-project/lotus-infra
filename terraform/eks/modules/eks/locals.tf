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
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/frrst"
      username = "frrst"
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
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/dealbot-controller"
      username = "dealbot-controller"
      groups = [
        "ntwk-mainnet-dealbot-edit",
        "ntwk-nerpanet-dealbot-edit",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/hannah.howard"
      username = "hannah.howard"
      groups = [
        "ntwk-mainnet-dealbot-edit",
        "ntwk-nerpanet-dealbot-edit",
        "ntwk-mainnet-storetheindex-edit",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/willscott"
      username = "willscott"
      groups = [
        "ntwk-mainnet-dealbot-edit",
        "ntwk-nerpanet-dealbot-edit",
        "ntwk-mainnet-storetheindex-edit",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/raulk"
      username = "raulk"
      groups   = ["ntwk-mainnet-dealbot-exec"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/aarsh.shah"
      username = "aarsh.shah"
      groups   = [
        "ntwk-mainnet-dealbot-exec",
        "ntwk-mainnet-storetheindex-exec",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/masih"
      username = "masih"
      groups   = [
        "ntwk-mainnet-dealbot-exec",
        "ntwk-mainnet-storetheindex-exec",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/gammazero"
      username = "gammazero"
      groups   = [
        "ntwk-mainnet-dealbot-exec",
        "ntwk-mainnet-storetheindex-exec",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/marco"
      username = "marco"
      groups   = [
        "ntwk-mainnet-dealbot-exec",
        "ntwk-mainnet-storetheindex-exec",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/dvd"
      username = "dvd"
      groups   = [
        "ntwk-mainnet-dealbot-exec",
        "ntwk-mainnet-storetheindex-exec",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/adlrocha"
      username = "adlrocha"
      groups   = [
        "ntwk-mainnet-dealbot-exec",
        "ntwk-mainnet-storetheindex-exec",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/mvdan"
      username = "mvdan"
      groups   = [
        "ntwk-mainnet-dealbot-exec",
        "ntwk-mainnet-storetheindex-exec",
      ]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/circleci-sentinel-infra"
      username = "circleci-sentinel-infra"
      groups   = ["system:masters"]
    },
  ]

  tags = {
    "Environment" = "${local.name}"
    "Terraform"   = "yes"
  }
}
