resource "aws_route53_zone" "fildev_domain" {
  provider = aws.us-east-1
  name     = local.domain_name
}
