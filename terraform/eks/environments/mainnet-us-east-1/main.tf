terraform {
  backend "s3" {
    bucket         = "filecoin-mainnet-terraform-state"
    key            = "filecoin-mainnet-eks-us-east-1.tfstate"
    dynamodb_table = "filecoin-mainnet-terraform-state"
    region         = "us-east-1"
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
