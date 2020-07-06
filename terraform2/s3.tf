resource "aws_s3_bucket" "fildev_networks" {
  bucket = "fildev-networks"
  acl    = "private"

  tags = {
    Name        = "fildev-networks"
    Environment = "prod"
  }
}

resource "aws_iam_instance_profile" "sectors" {
  name = "sealed-sectors-access"
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
        "arn:aws:s3:::fildev-networks",
        "arn:aws:s3:::fildev-networks/*"
      ]
    }
  ]
}
EOF
}

