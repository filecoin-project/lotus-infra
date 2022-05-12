terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "filecoin-s3.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "filecoin"
}

locals {
  bucket_name = "filecoin-chain-archiver-development"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "PublicRead"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket", "s3:GetObject", "s3:GetObjectVersion"
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
  }
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = local.bucket_name
  acl    = "public-read"

  block_public_acls       = false
  block_public_policy     = false

  attach_policy           = true
  policy                  = data.aws_iam_policy_document.bucket_policy.json

  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  lifecycle_rule = [
    {
      id      = "all"
      enabled = true
      expiration = {
        days = 1
      }
    }
  ]
}

resource "aws_iam_user" "s3_user" {
  name = "${local.bucket_name}-user"
}

resource "aws_iam_policy" "policy" {
  name        = "policy"
  description = "policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetObject", "s3:PutObject"],
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}",
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "attach" {
  user       = aws_iam_user.s3_user.name
  policy_arn = aws_iam_policy.policy.arn
}
