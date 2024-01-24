provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "filecoin_terraform_state" {
  name           = "buttterfly-network-terraform-state"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "filecoin_terraform_state" {
  bucket = "filoz-terraform-state"

  versioning {
    enabled = true
  }
}
