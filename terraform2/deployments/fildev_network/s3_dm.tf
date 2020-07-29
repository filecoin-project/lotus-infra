resource "aws_s3_bucket_policy" "dm" {
  bucket = local.bucket_name
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
