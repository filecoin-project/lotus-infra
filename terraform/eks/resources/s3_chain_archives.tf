resource "aws_s3_bucket" "chain_archives" {
  bucket = "${var.prefix}-chain-archives"
  acl    = "private"

  tags = merge(local.tags, {
    Name = "chain-archives"
  })
}

locals {
  OIDC_URL  = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
  OIDC_ARN  = aws_iam_openid_connect_provider.cluster.arn
  NAMESPACE = "default"

  SA_NAME_WRITE_ACCESS = "chain-archives-write"
  SA_NAME_READ_ACCESS  = "chain-archives-read"
}

resource "aws_iam_role" "chain_archives_write_access" {
  name = "chain-archives-write-access"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Principal": {
         "Federated": "${local.OIDC_ARN}"
      },
      "Effect": "Allow",
      "Condition": {
        "StringEquals": {
          "${local.OIDC_URL}:sub": "system:serviceaccount:${local.NAMESPACE}:${local.SA_NAME_WRITE_ACCESS}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "chain_archives_write_access" {
  name = "chain-archives-write-access"
  role = aws_iam_role.chain_archives_write_access.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": [
        "arn:aws:s3:::${var.prefix}-chain-archives"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.prefix}-chain-archives/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "chain_archives_read_access" {
  name = "chain-archives-read-access"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Principal": {
         "Federated": "${local.OIDC_ARN}"
      },
      "Effect": "Allow",
      "Condition": {
        "StringEquals": {
          "${local.OIDC_URL}:sub": "system:serviceaccount:${local.NAMESPACE}:${local.SA_NAME_READ_ACCESS}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "chain_archives_read_access" {
  name = "chain-archives-read-access"
  role = aws_iam_role.chain_archives_read_access.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": [
        "arn:aws:s3:::${var.prefix}-chain-archives"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.prefix}-chain-archives/*"
      ]
    }
  ]
}
EOF
}
