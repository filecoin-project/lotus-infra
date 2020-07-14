locals {
  bucket_name = "fildev-network"
}

resource "aws_s3_bucket" "fildev_network" {
  bucket = local.bucket_name
  acl    = "private"

  tags = {
    Name        = local.bucket_name
    Environment = "prod"
  }
}

resource "aws_iam_instance_profile" "sectors" {
  name = "${local.bucket_name}-access"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "read-access"
  path = "/"

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
  name = "sector-ro"
  role = aws_iam_role.role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
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
  name = "${local.bucket_name}-access-write"
  role = aws_iam_role.role_write.name
}

resource "aws_iam_role" "role_write" {
  name = "write-access"
  path = "/"

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
  name = "sector-rw"
  role = aws_iam_role.role_write.id

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

