terraform {
  backend "s3" {
    bucket         = "filecoin-mainnet-terraform-state"
    key            = "filecoin-mainnet-s3-network-snapshots.tfstate"
    dynamodb_table = "filecoin-mainnet-terraform-state"
    region         = "us-east-1"
    profile        = "mainnet"
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "mainnet"
}

locals {
  deployments = {
    "mainnet" = {
      bucket_name = "filecoin-snapshots-mainnet"
    }
    "calibrationnet" = {
      bucket_name = "filecoin-snapshots-calibrationnet"
    }
  }
}

module "s3_snapshot_bucket" {
  source = "../../modules/s3_snapshot_bucket"
  for_each = local.deployments

  bucket_name = "${each.value.bucket_name}"
}
