provider "aws" {
  region  = "us-west-2"
  profile = "filecoin"
}

terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "lotus-painnet-us-east-1.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}
