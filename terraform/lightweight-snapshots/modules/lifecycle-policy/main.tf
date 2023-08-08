data "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_configuration" {
  bucket = data.aws_s3_bucket.bucket.id

  rule {
    id     = var.rule_id
    status = var.status
    filter {
      prefix = var.path_prefix
    }
    expiration {
      days = var.expiration_timeframe
    }
  }
}
