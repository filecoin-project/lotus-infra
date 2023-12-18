# use default aws credentials.
provider "aws" {
  alias = "us-west-2"
  region  = "us-west-2"
}

provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "filecoin-mainnet-terraform-state"
    key            = "filecoin-mainnet-fildev-network-updated.tfstate"
    dynamodb_table = "filecoin-mainnet-terraform-state"
    region         = "us-east-1"
    profile        = "mainnet"
  }
}
