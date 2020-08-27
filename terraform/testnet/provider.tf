# use default aws credentials.

provider "aws" {
  region = "us-east-1"
  profile = "filecoin"
}

terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "testnet-packet-us-east-1.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}

provider "packet" {
  auth_token = var.packet_auth_token
}


provider "dnsimple" {
  token   = var.dnsimple_token
  account = var.dnsimple_account
}
