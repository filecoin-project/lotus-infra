terraform {
  backend "s3" {
    bucket         = "filecoin-mainnet-terraform-state"
    key            = "lightweight-snapshots/production/mainnet.tfstate"
    dynamodb_table = "filecoin-mainnet-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin-production"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.20.1"
    }
  }
}

provider "aws" {
  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  endpoints {
    s3 = "https://eafecb340a3ce23027e1eba779ed4d91.r2.cloudflarestorage.com"
  }

  # Region is required, otherwise you get back a cryptic 400 error when
  # it tries to resolve data.aws_s3_bucket in r2
  region  = "auto"
  profile = var.cloudflare_profile
}

module "lifecycle-policy" {
  source               = "../../modules/lifecycle-policy"
  bucket_name          = "filecoin-snapshots-mainnet-production"
  expiration_timeframe = 90  # Temporary until Marcus works out what to do with `latest`
}
