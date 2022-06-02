variable "bucket_name" {
  type = string
}

locals {
  bucket_name = "${var.bucket_name}"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "PublicRead"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectVersion"
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
      filter  = {
        prefix = "minimal/"
      }
      expiration = {
        days = 7
      }
    }
  ]
}

resource "aws_iam_user" "s3_user" {
  name = "s3-user-${local.bucket_name}"
}

resource "aws_iam_policy" "policy" {
  name        = "${local.bucket_name}-bucket-policy"
  description = "Provide basic operations to bucket user"
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
