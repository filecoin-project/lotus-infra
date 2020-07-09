locals {
  website_bucket = "www.${substr(aws_route53_zone.subdomain.name, 0, length(aws_route53_zone.subdomain.name) - 1)}"
}

resource "aws_s3_bucket" "website" {
  bucket = local.website_bucket
  acl    = "public-read"

  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"PublicRead",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${local.website_bucket}/*"]
    }
  ]
}
EOF

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name        = "www-${aws_route53_zone.subdomain.name}"
    Environment = var.environment
  }
}
/*
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.website.website_endpoint}"
    origin_id = "s3-www-fish-fildev-network"

    // The origin must be http even if it's on S3 for redirects to work properly
    // so the website_endpoint is used and http-only as S3 doesn't support https for this
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  aliases = [local.website_bucket]

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "s3-www-fish-fildev-network"

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 500
    max_ttl = 900
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-west-2:657871693752:certificate/4fd5b96b-47d2-410b-a2dc-14093d20f7a2"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
*/
