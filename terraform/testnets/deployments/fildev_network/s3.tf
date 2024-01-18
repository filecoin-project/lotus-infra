locals {
  bucket_name = "fildev-network-sectors"
}

resource "aws_s3_bucket" "fildev_network" {
  provider = aws.us-west-2
  bucket   = local.bucket_name
  acl      = "private"

  tags = {
    Name        = local.bucket_name
    Environment = "prod"
  }
}

resource "aws_iam_instance_profile" "sectors" {
  provider = aws.us-west-2
  name     = "${local.bucket_name}-access"
  role     = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  provider = aws.us-west-2
  name     = "read-access"
  path     = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
         "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "sector_ro" {
  provider = aws.us-west-2
  name     = "sector-ro"
  role     = aws_iam_role.role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetObject"],
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}",
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
    }
  ]
}
EOF
}



##################################################


resource "aws_iam_instance_profile" "presealer" {
  provider = aws.us-west-2
  name     = "${local.bucket_name}-access-write"
  role     = aws_iam_role.role_write.name
}

resource "aws_iam_role" "role_write" {
  provider = aws.us-west-2
  name     = "write-access"
  path     = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
         "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "sector_rw" {
  provider = aws.us-west-2
  name     = "sector-rw"
  role     = aws_iam_role.role_write.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}"
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
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
    }
  ]
}
EOF
}

