locals {
  cluster_admins = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/marcus",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/travisperson",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cory",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/circleci-lotus",
  ]
  cluster_exec = []
  lotus_admins = []
  lotus_exec = []
  sentinel_admins = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/iand",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/mg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/frrist",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/hsanjuan",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/circleci-sentinel-infra",
  ]
  sentinel_exec = []
  dealbot_admins = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/hannah.howard",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/willscott",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/dealbot-controller",
  ]
  dealbot_exec = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/raulk",
  ]
  
  assume_role_policies = {
    "ntwk-butterfly-bootstrap-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_bootstrap_admin_policy,
    "ntwk-butterfly-bootstrap-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_bootstrap_exec_policy,
    "ntwk-butterfly-dealbot-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_dealbot_admin_policy,
    "ntwk-butterfly-dealbot-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_dealbot_exec_policy,
    "ntwk-butterfly-disputer-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_disputer_admin_policy,
    "ntwk-butterfly-disputer-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_disputer_exec_policy,
    "ntwk-butterfly-fullnode-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_fullnode_admin_policy,
    "ntwk-butterfly-fullnode-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_fullnode_exec_policy,
    "ntwk-butterfly-sentinel-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_sentinel_admin_policy,
    "ntwk-butterfly-sentinel-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_sentinel_exec_policy,
    "ntwk-butterfly-stats-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_stats_admin_policy,
    "ntwk-butterfly-stats-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_butterfly_stats_exec_policy,
    "ntwk-calibnet-bootstrap-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_bootstrap_admin_policy,
    "ntwk-calibnet-bootstrap-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_bootstrap_exec_policy,
    "ntwk-calibnet-dealbot-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_dealbot_admin_policy,
    "ntwk-calibnet-dealbot-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_dealbot_exec_policy,
    "ntwk-calibnet-disputer-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_disputer_admin_policy,
    "ntwk-calibnet-disputer-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_disputer_exec_policy,
    "ntwk-calibnet-fullnode-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_fullnode_admin_policy,
    "ntwk-calibnet-fullnode-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_fullnode_exec_policy,
    "ntwk-calibnet-sentinel-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_sentinel_admin_policy,
    "ntwk-calibnet-sentinel-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_sentinel_exec_policy,
    "ntwk-calibnet-stats-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_stats_admin_policy,
    "ntwk-calibnet-stats-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_calibnet_stats_exec_policy,
    "ntwk-mainnet-bootstrap-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_bootstrap_admin_policy,
    "ntwk-mainnet-bootstrap-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_bootstrap_exec_policy,
    "ntwk-mainnet-dealbot-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_dealbot_admin_policy,
    "ntwk-mainnet-dealbot-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_dealbot_exec_policy,
    "ntwk-mainnet-disputer-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_disputer_admin_policy,
    "ntwk-mainnet-disputer-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_disputer_exec_policy,
    "ntwk-mainnet-fullnode-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_fullnode_admin_policy,
    "ntwk-mainnet-fullnode-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_fullnode_exec_policy,
    "ntwk-mainnet-sentinel-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_sentinel_admin_policy,
    "ntwk-mainnet-sentinel-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_sentinel_exec_policy,
    "ntwk-mainnet-stats-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_stats_admin_policy,
    "ntwk-mainnet-stats-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_mainnet_stats_exec_policy,
    "ntwk-nerpanet-bootstrap-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_bootstrap_admin_policy,
    "ntwk-nerpanet-bootstrap-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_bootstrap_exec_policy,
    "ntwk-nerpanet-dealbot-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_dealbot_admin_policy,
    "ntwk-nerpanet-dealbot-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_dealbot_exec_policy,
    "ntwk-nerpanet-disputer-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_disputer_admin_policy,
    "ntwk-nerpanet-disputer-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_disputer_exec_policy,
    "ntwk-nerpanet-fullnode-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_fullnode_admin_policy,
    "ntwk-nerpanet-fullnode-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_fullnode_exec_policy,
    "ntwk-nerpanet-sentinel-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_sentinel_admin_policy,
    "ntwk-nerpanet-sentinel-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_sentinel_exec_policy,
    "ntwk-nerpanet-stats-admin": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_stats_admin_policy,
    "ntwk-nerpanet-stats-exec": data.aws_iam_policy_document.kubectl_assume_role_ntwk_nerpanet_stats_exec_policy,
  }
}

# Butterfly
data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_bootstrap_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_bootstrap_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_dealbot_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.dealbot_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_dealbot_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.dealbot_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_disputer_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_disputer_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}


data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_fullnode_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_fullnode_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_sentinel_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_sentinel_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_stats_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_butterfly_stats_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}



# Calibrationnet
data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_bootstrap_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_bootstrap_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_dealbot_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.dealbot_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_dealbot_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.dealbot_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_disputer_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_disputer_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}


data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_fullnode_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_fullnode_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_sentinel_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_sentinel_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_stats_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_calibnet_stats_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}



# Mainnet
data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_bootstrap_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_bootstrap_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_dealbot_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.dealbot_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_dealbot_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.dealbot_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_disputer_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_disputer_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}


data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_fullnode_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_fullnode_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_sentinel_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_sentinel_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_stats_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_mainnet_stats_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}



# Nerpanet
data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_bootstrap_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_bootstrap_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_dealbot_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.dealbot_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_dealbot_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.dealbot_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_disputer_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_disputer_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}


data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_fullnode_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_fullnode_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_sentinel_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_sentinel_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_stats_admin_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_admins, local.lotus_admins)
    }
  }
}

data "aws_iam_policy_document" "kubectl_assume_role_ntwk_nerpanet_stats_exec_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
principals {
      type        = "AWS"
      identifiers = concat(local.cluster_exec, local.lotus_exec)
    }
  }
}
