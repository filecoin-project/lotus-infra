output "s3_bucket_id" {
  description = "The name of the bucket."
  value = {
    for k, v in module.s3_snapshot_bucket: k => v.s3_bucket_id
  }
}

output "s3_bucket_bucket_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com."
  value = {
    for k, v in module.s3_snapshot_bucket: k => v.s3_bucket_bucket_domain_name
  }
}

output "iam_user" {
  description = "The iam user created for the bucket"
  value = {
    for k, v in module.s3_snapshot_bucket: k => v.iam_user
  }
}
