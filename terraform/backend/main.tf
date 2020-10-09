provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "filecoin_terraform_state" {
  name           = "filecoin-mainnet-terraform-state"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "filecoin_ssm_terraform_state" {
  name           = "filecoin-mainnet-ssm-terraform-state"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "filecoin_terraform_state" {
  bucket = "filecoin-mainnet-terraform-state"

  versioning {
    enabled = true
  }
}

resource "aws_key_pair" "filecoin-mainnet" {
  key_name   = "filecoin-mainnet"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMMuR4/FOOyVg/WaFO7h1vAAcjhO61ypTND4Y363Nyho32FeEiIcp70u7JpkWBqdyZ9vs38CSmFUC2uqTfphdD9fY+GNQfwPhAvOJodPGg3eH+5rjUd9BAiCPvRmqSR9GoCndfp/8+dAMCMnLImFKGASk34eHBr/NYtPZD50a/3DYArXdso2XR77O3y9xKLzroqcM9yOWbw6QkgoE/jxxDByFI0ZV/dJCgGFmtKFR1SXP0LCkAsmvrcli5gpLlk8MXOgQstFolzlgqbEp6O3Aywq5gEf1sJcmul2yY5WsKeWjSQT1jd/K3C5Qlfl5zBj6J7XeI08FGDhtUbhDqnDS6QwsUjDL3qRoWsgGrIZ0vRiVUDiDkC7pMIRb0ZJIvMeduVJIMRmyaF/+L9wdg+GCA9Occb36ZJe0v+9nCGQeRS6F1PVUN8VnjcqVjLeN/9w9RH1DuaenPwd+M3hTIbA5o9G3imU8wjakVOn17ahrUu/k+if/6v/anaKvMfwIQPQa8do7Y7g9u8TF3xDqWGB/6dNA/sUafqzVDPDdVPFmsw9ZxKhgKpxnF8FTFaE9IOXU7Abh40iuejQkgSSq+XEnckFmr7VTcxWkvw/tr9S8W25OUISlh3hwtCru27SBJh9tnu1+WakXjHBIR2I6MPbIXv1Eg2hCB1bbYuy+mWuMy3Q== infra-accounts+filecoin-mainnet@protocol.ai"
}
