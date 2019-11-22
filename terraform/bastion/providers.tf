provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket  = "filecoin-terraform-state"
    key     = "lotus-bastion-us-east-1.tfstate"
    region  = "us-east-1"
    profile = "filecoin"
  }
}
