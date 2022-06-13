terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "filecoin-s3-network-snapshots.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}

provider "aws" {
  region = "us-east-2"
  profile = "filecoin"
}

locals {
  deployments = {
    "mainnet" = {
      bucket_name = "filecoin-snapshots-mainnet-development"
    }
    "calibrationnet" = {
      bucket_name = "filecoin-snapshots-calibrationnet-development"
    }
    "butterflynet" = {
      bucket_name = "filecoin-snapshots-butterflynet-development"
    }
  }
}

module "s3_snapshot_bucket" {
  source = "../../modules/s3_snapshot_bucket"
  for_each = local.deployments

  bucket_name = "${each.value.bucket_name}"
}
