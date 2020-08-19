# use default aws credentials.
provider "aws" {
  alias = "us-west-2"
  region  = "us-west-2"
  profile = "filecoin"
}

provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
  profile = "filecoin"
}

terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "fildev-network-us-west-2.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}
