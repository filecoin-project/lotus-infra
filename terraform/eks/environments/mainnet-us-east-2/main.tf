terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "filecoin-mainnet-eks-us-east-2.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}

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
