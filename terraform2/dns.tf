resource "aws_route53_zone" "lotus_domain" {
  name = local.domain_name
  vpc {
    vpc_id = aws_vpc.lotus_vpc.id
  }
}
