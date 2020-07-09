resource "aws_route53_zone" "fildev_domain" {
  name = local.domain_name
}
