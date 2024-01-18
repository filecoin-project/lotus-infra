# use default aws credentials.
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "filoz-terraform-state"
    key            = "butterfly-network.tfstate"
    dynamodb_table = "buttterfly-network-terraform-state"
    region         = "us-east-1"
  }
}
