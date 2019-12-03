provider "packet" {
  auth_token = var.packet_auth_token
}

provider "aws" {
  region  = "us-east-1"
  profile = "filecoin"
}

provider "dnsimple" {
  token   = var.dnsimple_token
  account = var.dnsimple_account
}

terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "lotus-testnet-us-east-1.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}
