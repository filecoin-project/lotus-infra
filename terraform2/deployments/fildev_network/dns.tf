resource "aws_route53_zone" "fildev_domain" {
  provider = aws.us-west-2
  name = local.domain_name
}
