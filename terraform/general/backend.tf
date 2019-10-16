terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "lotus-dns-us-east-1.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}
