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
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-bootstrap-admin"
      username = "ntwk-butterfly-bootstrap-admin"
      groups = ["ntwk-butterfly-bootstrap-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-bootstrap-exec"
      username = "ntwk-butterfly-bootstrap-exec"
      groups = ["ntwk-butterfly-bootstrap-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-dealbot-admin"
      username = "ntwk-butterfly-dealbot-admin"
      groups = ["ntwk-butterfly-dealbot-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-dealbot-exec"
      username = "ntwk-butterfly-dealbot-exec"
      groups = ["ntwk-butterfly-dealbot-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-disputer-admin"
      username = "ntwk-butterfly-disputer-admin"
      groups = ["ntwk-butterfly-disputer-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-disputer-exec"
      username = "ntwk-butterfly-disputer-exec"
      groups = ["ntwk-butterfly-disputer-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-fullnode-admin"
      username = "ntwk-butterfly-fullnode-admin"
      groups = ["ntwk-butterfly-fullnode-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-fullnode-exec"
      username = "ntwk-butterfly-fullnode-exec"
      groups = ["ntwk-butterfly-fullnode-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-sentinel-admin"
      username = "ntwk-butterfly-sentinel-admin"
      groups = ["ntwk-butterfly-sentinel-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-sentinel-exec"
      username = "ntwk-butterfly-sentinel-exec"
      groups = ["ntwk-butterfly-sentinel-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-stats-admin"
      username = "ntwk-butterfly-stats-admin"
      groups = ["ntwk-butterfly-stats-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-butterfly-stats-exec"
      username = "ntwk-butterfly-stats-exec"
      groups = ["ntwk-butterfly-stats-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-bootstrap-admin"
      username = "ntwk-calibnet-bootstrap-admin"
      groups = ["ntwk-calibnet-bootstrap-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-bootstrap-exec"
      username = "ntwk-calibnet-bootstrap-exec"
      groups = ["ntwk-calibnet-bootstrap-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-dealbot-admin"
      username = "ntwk-calibnet-dealbot-admin"
      groups = ["ntwk-calibnet-dealbot-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-dealbot-exec"
      username = "ntwk-calibnet-dealbot-exec"
      groups = ["ntwk-calibnet-dealbot-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-disputer-admin"
      username = "ntwk-calibnet-disputer-admin"
      groups = ["ntwk-calibnet-disputer-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-disputer-exec"
      username = "ntwk-calibnet-disputer-exec"
      groups = ["ntwk-calibnet-disputer-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-fullnode-admin"
      username = "ntwk-calibnet-fullnode-admin"
      groups = ["ntwk-calibnet-fullnode-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-fullnode-exec"
      username = "ntwk-calibnet-fullnode-exec"
      groups = ["ntwk-calibnet-fullnode-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-sentinel-admin"
      username = "ntwk-calibnet-sentinel-admin"
      groups = ["ntwk-calibnet-sentinel-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-sentinel-exec"
      username = "ntwk-calibnet-sentinel-exec"
      groups = ["ntwk-calibnet-sentinel-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-stats-admin"
      username = "ntwk-calibnet-stats-admin"
      groups = ["ntwk-calibnet-stats-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-calibnet-stats-exec"
      username = "ntwk-calibnet-stats-exec"
      groups = ["ntwk-calibnet-stats-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-bootstrap-admin"
      username = "ntwk-mainnet-bootstrap-admin"
      groups = ["ntwk-mainnet-bootstrap-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-bootstrap-exec"
      username = "ntwk-mainnet-bootstrap-exec"
      groups = ["ntwk-mainnet-bootstrap-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-dealbot-admin"
      username = "ntwk-mainnet-dealbot-admin"
      groups = ["ntwk-mainnet-dealbot-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-dealbot-exec"
      username = "ntwk-mainnet-dealbot-exec"
      groups = ["ntwk-mainnet-dealbot-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-disputer-admin"
      username = "ntwk-mainnet-disputer-admin"
      groups = ["ntwk-mainnet-disputer-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-disputer-exec"
      username = "ntwk-mainnet-disputer-exec"
      groups = ["ntwk-mainnet-disputer-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-fullnode-admin"
      username = "ntwk-mainnet-fullnode-admin"
      groups = ["ntwk-mainnet-fullnode-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-fullnode-exec"
      username = "ntwk-mainnet-fullnode-exec"
      groups = ["ntwk-mainnet-fullnode-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-sentinel-admin"
      username = "ntwk-mainnet-sentinel-admin"
      groups = ["ntwk-mainnet-sentinel-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-sentinel-exec"
      username = "ntwk-mainnet-sentinel-exec"
      groups = ["ntwk-mainnet-sentinel-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-stats-admin"
      username = "ntwk-mainnet-stats-admin"
      groups = ["ntwk-mainnet-stats-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-mainnet-stats-exec"
      username = "ntwk-mainnet-stats-exec"
      groups = ["ntwk-mainnet-stats-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-bootstrap-admin"
      username = "ntwk-nerpanet-bootstrap-admin"
      groups = ["ntwk-nerpanet-bootstrap-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-bootstrap-exec"
      username = "ntwk-nerpanet-bootstrap-exec"
      groups = ["ntwk-nerpanet-bootstrap-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-dealbot-admin"
      username = "ntwk-nerpanet-dealbot-admin"
      groups = ["ntwk-nerpanet-dealbot-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-dealbot-exec"
      username = "ntwk-nerpanet-dealbot-exec"
      groups = ["ntwk-nerpanet-dealbot-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-disputer-admin"
      username = "ntwk-nerpanet-disputer-admin"
      groups = ["ntwk-nerpanet-disputer-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-disputer-exec"
      username = "ntwk-nerpanet-disputer-exec"
      groups = ["ntwk-nerpanet-disputer-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-fullnode-admin"
      username = "ntwk-nerpanet-fullnode-admin"
      groups = ["ntwk-nerpanet-fullnode-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-fullnode-exec"
      username = "ntwk-nerpanet-fullnode-exec"
      groups = ["ntwk-nerpanet-fullnode-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-sentinel-admin"
      username = "ntwk-nerpanet-sentinel-admin"
      groups = ["ntwk-nerpanet-sentinel-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-sentinel-exec"
      username = "ntwk-nerpanet-sentinel-exec"
      groups = ["ntwk-nerpanet-sentinel-exec"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ntwk-nerpanet-stats-admin"
      username = "ntwk-nerpanet-stats-admin"
      groups = ["ntwk-nerpanet-stats-admin"]
    },
  ]

  tags = {
    "Environment" = "${local.name}"
    "Terraform"   = "yes"
  }
}
