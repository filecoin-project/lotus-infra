resource "aws_route53_zone" "fildev_domain" {
  name = local.domain_name
  #vpc {
  #vpc_id = module.lotus_vpc.vpc_id
  #}
}
