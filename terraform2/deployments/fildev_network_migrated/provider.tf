# use default aws credentials.
provider "aws" {
  alias = "us-west-2"
  region  = "us-west-2"
  profile = "mainnet"
}

provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
  profile = "mainnet"
}

terraform {
  backend "s3" {
    bucket         = "filecoin-mainnet-terraform-state"
    key            = "filecoin-mainnet-fildev-network.tfstate"
    dynamodb_table = "filecoin-mainnet-terraform-state"
    region         = "us-east-1"
    profile        = "mainnet"
  }
}
