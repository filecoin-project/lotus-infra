module "main" {
  source = "../../resources"

  aws_profile                                = var.aws_profile
  prefix                                     = var.prefix
  region                                     = var.region
  cidr                                       = var.cidr
  private_subnets                            = var.private_subnets
  public_subnets                             = var.public_subnets
  eks_iam_usernames                          = var.eks_iam_usernames
  kubeconfig_aws_authenticator_env_variables = var.kubeconfig_aws_authenticator_env_variables
}

