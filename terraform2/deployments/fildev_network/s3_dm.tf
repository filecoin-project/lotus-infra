resource "aws_s3_bucket_policy" "dm" {
  bucket = local.bucket_name
  provider = aws.us-west-2
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["arn:aws:iam::826594180919:user/dmob-devops"]},
      "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["arn:aws:iam::826594180919:user/dmob-devops"]},
      "Action": ["s3:GetObject"],
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_bucket_policy" "migration" {
  bucket = local.bucket_name
  provider = aws.us-west-2
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["arn:aws:iam::759815798766:user/travis"]},
      "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["arn:aws:iam::759815798766:user/travis"]},
      "Action": ["s3:GetObject"],
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
    }
  ]
}
EOF
}
